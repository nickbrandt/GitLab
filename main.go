package main

import (
	"compress/gzip"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path"
	"regexp"
	"strings"
)

type gitHandler struct {
	method      string
	regexp      *regexp.Regexp
	handle_func func(string, string, string, http.ResponseWriter, *http.Request)
	rpc         string
}

var http_client = &http.Client{}
var repo_root string
var listen_addr = flag.String("listen_addr", "localhost:8181", "Listen address for HTTP server")

var git_handlers = [...]gitHandler{
	gitHandler{"GET", regexp.MustCompile(`\A(/..*)/info/refs\z`), handle_get_info_refs, ""},
	gitHandler{"POST", regexp.MustCompile(`\A(/..*)/git-upload-pack\z`), handle_post_rpc, "git-upload-pack"},
	gitHandler{"POST", regexp.MustCompile(`\A(/..*)/git-receive-pack\z`), handle_post_rpc, "git-receive-pack"},
}

func main() {
	flag.Parse()
	repo_root = flag.Arg(0)
	log.Printf("repo_root: %s", repo_root)
	http.HandleFunc("/", git_handler)
	log.Fatal(http.ListenAndServe(*listen_addr, nil))
}

func git_handler(w http.ResponseWriter, r *http.Request) {
	var user string
	log.Print(r.Method, " ", r.URL)
	for _, g := range git_handlers {
		path_match := g.regexp.FindStringSubmatch(r.URL.Path)
		if r.Method == g.method && path_match != nil {
			auth_response := do_auth_request(r)
			if auth_response.StatusCode != 200 {
				for k, v := range auth_response.Header {
					w.Header()[k] = v
				}
				w.WriteHeader(auth_response.StatusCode)
				io.Copy(w, auth_response.Body)
				return
			}
			if _, err := fmt.Fscan(auth_response.Body, user); err != nil {
				fail_500(w, err)
			}
			g.handle_func(user, g.rpc, path.Join(repo_root, path_match[1]), w, r)
			return
		}
	}
	log.Print("Reached end of dispatch for loop")
	w.WriteHeader(404)
}

func do_auth_request(r *http.Request) *http.Response {
	var err error
	result := &http.Response{}
	url := fmt.Sprintf("http://localhost:8080%s", r.URL.RequestURI())
	auth_req, err := http.NewRequest(r.Method, url, nil)
	if err != nil {
		result.StatusCode = 500
		return result
	}
	for k, v := range r.Header {
		auth_req.Header[k] = v
	}
	result, err = http_client.Do(auth_req)
	if err != nil {
		result.StatusCode = 500
		return result
	}
	return result
}

func handle_get_info_refs(user string, _ string, path string, w http.ResponseWriter, r *http.Request) {
	rpc := r.URL.Query().Get("service")
	switch rpc {
	case "git-upload-pack", "git-receive-pack":
		cmd := exec.Command("git", strings.TrimPrefix(rpc, "git-"), "--stateless-rpc", "--advertise-refs", path)
		cmd.Env = []string{fmt.Sprintf("PATH=%s", os.Getenv("PATH")), fmt.Sprintf("GL_ID=%s", user)}
		stdout, err := cmd.StdoutPipe()
		if err != nil {
			fail_500(w, err)
			return
		}
		if err := cmd.Start(); err != nil {
			fail_500(w, err)
			return
		}
		w.Header().Add("Content-Type", fmt.Sprintf("application/x-%s-advertisement", rpc))
		no_cache(w)
		fmt.Fprintf(w, "%s0000", pkt_line(fmt.Sprintf("# service=%s\n", rpc)))
		if _, err := io.Copy(w, stdout); err != nil {
			fail_500(w, err)
			return
		}
		if err := cmd.Wait(); err != nil {
			fail_500(w, err)
			return
		}
	case "":
		log.Print("dumb info refs")
	}
}

func handle_post_rpc(user string, rpc string, path string, w http.ResponseWriter, r *http.Request) {
	var body io.Reader
	var err error
	if r.Header.Get("Content-Encoding") == "gzip" {
		body, err = gzip.NewReader(r.Body)
		if err != nil {
			fail_500(w, err)
			return
		}
	} else {
		body = r.Body
	}
	cmd := exec.Command("git", strings.TrimPrefix(rpc, "git-"), "--stateless-rpc", path)
	cmd.Env = []string{fmt.Sprintf("PATH=%s", os.Getenv("PATH")), fmt.Sprintf("GL_ID=%s", user)}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fail_500(w, err)
		return
	}
	stdin, err := cmd.StdinPipe()
	if err != nil {
		fail_500(w, err)
		return
	}
	if err := cmd.Start(); err != nil {
		fail_500(w, err)
		return
	}
	w.Header().Add("Content-Type", fmt.Sprintf("application/x-%s-result", rpc))
	no_cache(w)
	if _, err := io.Copy(stdin, body); err != nil {
		fail_500(w, err)
		return
	}
	stdin.Close()
	if _, err := io.Copy(w, stdout); err != nil {
		fail_500(w, err)
		return
	}
	if err := cmd.Wait(); err != nil {
		fail_500(w, err)
		return
	}
}

func pkt_line(s string) string {
	return fmt.Sprintf("%04x%s", len(s)+4, s)
}

func fail_500(w http.ResponseWriter, err error) {
	w.WriteHeader(500)
	log.Print(err)
}

func no_cache(w http.ResponseWriter) {
	w.Header().Add("Cache-Control", "no-cache")
}
