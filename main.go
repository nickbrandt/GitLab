package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os/exec"
	"regexp"
	"strings"
)

type gitHandler struct {
	method      string
	regexp      *regexp.Regexp
	handle_func func(string, http.ResponseWriter, *http.Request)
	rpc         string
}

var git_handlers = [...]gitHandler{
	gitHandler{"GET", regexp.MustCompile(`\A(/..*)/info/refs\z`), handle_get_info_refs, ""},
	gitHandler{"POST", regexp.MustCompile(`\A(/..*)/git-upload-pack\z`), handle_post_rpc, "git-upload-pack"},
	gitHandler{"POST", regexp.MustCompile(`\A(/..*)/git-receive-pack\z`), handle_post_rpc, "git-receive-pack"},
}

func main() {
	http.HandleFunc("/", git_handler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func git_handler(w http.ResponseWriter, r *http.Request) {
	log.Print(r)
	for _, g := range git_handlers {
		if r.Method == g.method && g.regexp.MatchString(r.URL.Path) {
			g.handle_func(g.rpc, w, r)
			return
		}
	}
	log.Print("Reached end of dispatch for loop")
	w.WriteHeader(404)
}

func handle_get_info_refs(_ string, w http.ResponseWriter, r *http.Request) {
	rpc := r.URL.Query().Get("service")
	switch rpc {
	case "git-upload-pack", "git-receive-pack":
		cmd := exec.Command("git", strings.TrimPrefix(rpc, "git-"), "--stateless-rpc", "--advertise-refs", "data/foo/bar.git")
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

func handle_post_rpc(rpc string, w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command("git", strings.TrimPrefix(rpc, "git-"), "--stateless-rpc", "data/foo/bar.git")
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
	if _, err := io.Copy(stdin, r.Body); err != nil {
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
