/*
gitlab-git-http-server handles 'smart' Git HTTP requests for GitLab

This HTTP server can service 'git clone', 'git push' etc. commands
from Git clients that use the 'smart' Git HTTP protocol (git-upload-pack
and git-receive-pack). It is intended to be deployed behind NGINX
(for request routing and SSL termination) with access to a GitLab
backend (for authentication and authorization) and local disk access
to Git repositories managed by GitLab.

This HTTP server replaces gitlab-grack.
*/
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

type gitService struct {
	method      string
	regexp      *regexp.Regexp
	handle_func func(string, string, string, http.ResponseWriter, *http.Request)
	rpc         string
}

var http_client = &http.Client{}
var path_traversal = regexp.MustCompile(`/../`)

// Command-line options
var repo_root string
var listen_addr = flag.String("listen_addr", "localhost:8181", "Listen address for HTTP server")
var auth_backend = flag.String("auth_backend", "http://localhost:8080", "Authentication/authorization backend")

var git_services = [...]gitService{
	gitService{"GET", regexp.MustCompile(`\A(/..*)/info/refs\z`), handle_get_info_refs, ""},
	gitService{"POST", regexp.MustCompile(`\A(/..*)/git-upload-pack\z`), handle_post_rpc, "git-upload-pack"},
	gitService{"POST", regexp.MustCompile(`\A(/..*)/git-receive-pack\z`), handle_post_rpc, "git-receive-pack"},
}

func main() {
	// Parse the command-line
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "\n  %s [OPTIONS] REPO_ROOT\n\nOptions:\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()
	repo_root = flag.Arg(0)
	if repo_root == "" {
		flag.Usage()
		os.Exit(1)
	}
	log.Printf("repo_root: %s", repo_root)

	http.HandleFunc("/", git_handler)
	log.Fatal(http.ListenAndServe(*listen_addr, nil))
}

func git_handler(w http.ResponseWriter, r *http.Request) {
	var gl_id string
	var path_match []string
	var g gitService
	var found_service bool

	log.Print(r.Method, " ", r.URL)

	// Look for a matching Git service
	for _, g = range git_services {
		path_match = g.regexp.FindStringSubmatch(r.URL.Path)
		if r.Method == g.method && path_match != nil {
			found_service = true
			break
		}
	}
	if !found_service {
		http.Error(w, "Not Found", 404)
		return
	}

	// Ask the auth backend if the request is allowed, and what the
	// user ID (GL_ID) is.
	auth_response, err := do_auth_request(r)
	if err != nil {
		fail_500(w, err)
		return
	}
	if auth_response.StatusCode != 200 {
		// The Git request is not allowed by the backend. Maybe the
		// client needs to send HTTP Basic credentials.  Forward the
		// response from the auth backend to our client. This includes
		// the 'WWW-Authentication' header that acts as a hint that
		// Basic auth credentials are needed.
		for k, v := range auth_response.Header {
			w.Header()[k] = v
		}
		w.WriteHeader(auth_response.StatusCode)
		io.Copy(w, auth_response.Body)
		return
	}

	// The auth backend validated the client request and told us who
	// the user is according to them (GL_ID). We must extract this
	// information from the auth response body.
	if _, err := fmt.Fscan(auth_response.Body, &gl_id); err != nil {
		fail_500(w, err)
		return
	}

	// Validate the path to the Git repository
	found_path := path_match[1]
	if !valid_path(found_path) {
		http.Error(w, "Not Found", 404)
		return
	}

	g.handle_func(gl_id, g.rpc, path.Join(repo_root, found_path), w, r)
}

func valid_path(p string) bool {
	if path_traversal.MatchString(p) {
		log.Printf("path traversal detected in %s", p)
		return false
	}

	// If /path/to/foo.git/objects exists then let's assume it is a valid Git
	// repository.
	if _, err := os.Stat(path.Join(repo_root, p, "objects")); err != nil {
		log.Print(err)
		return false
	}
	return true
}

func do_auth_request(r *http.Request) (result *http.Response, err error) {
	url := fmt.Sprintf("%s%s", *auth_backend, r.URL.RequestURI())
	auth_req, err := http.NewRequest(r.Method, url, nil)
	if err != nil {
		return nil, err
	}
	// Forward all headers from our client to the auth backend. This includes
	// HTTP Basic authentication credentials (the 'Authorization' header).
	for k, v := range r.Header {
		auth_req.Header[k] = v
	}
	return http_client.Do(auth_req)
}

func handle_get_info_refs(gl_id string, _ string, path string, w http.ResponseWriter, r *http.Request) {
	rpc := r.URL.Query().Get("service")
	if !(rpc == "git-upload-pack" || rpc == "git-receive-pack") {
		// The 'dumb' Git HTTP protocol is not supported
		http.Error(w, "Not Found", 404)
		return
	}

	// Prepare our Git subprocess
	cmd := exec.Command("git", sub_command(rpc), "--stateless-rpc", "--advertise-refs", path)
	set_cmd_env(cmd, gl_id)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fail_500(w, err)
		return
	}
	defer stdout.Close()
	if err := cmd.Start(); err != nil {
		fail_500(w, err)
		return
	}

	// Start writing the response
	w.Header().Add("Content-Type", fmt.Sprintf("application/x-%s-advertisement", rpc))
	header_no_cache(w)
	w.WriteHeader(200) // Don't bother with HTTP 500 from this point on, just panic
	if err := pkt_line(w, fmt.Sprintf("# service=%s\n", rpc)); err != nil {
		panic(err)
	}
	if err := pkt_flush(w); err != nil {
		panic(err)
	}
	if _, err := io.Copy(w, stdout); err != nil {
		panic(err)
	}
	if err := cmd.Wait(); err != nil {
		panic(err)
	}
}

func sub_command(rpc string) string {
	return strings.TrimPrefix(rpc, "git-")
}

func set_cmd_env(cmd *exec.Cmd, gl_id string) {
	cmd.Env = []string{
		fmt.Sprintf("PATH=%s", os.Getenv("PATH")),
		fmt.Sprintf("GL_ID=%s", gl_id),
	}
}

func handle_post_rpc(gl_id string, rpc string, path string, w http.ResponseWriter, r *http.Request) {
	var body io.Reader
	var err error

	// The client request body may have been gzipped.
	if r.Header.Get("Content-Encoding") == "gzip" {
		body, err = gzip.NewReader(r.Body)
		if err != nil {
			fail_500(w, err)
			return
		}
	} else {
		body = r.Body
	}

	// Prepare our Git subprocess
	cmd := exec.Command("git", sub_command(rpc), "--stateless-rpc", path)
	set_cmd_env(cmd, gl_id)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fail_500(w, err)
		return
	}
	defer stdout.Close()
	stdin, err := cmd.StdinPipe()
	if err != nil {
		fail_500(w, err)
		return
	}
	defer stdin.Close()
	if err := cmd.Start(); err != nil {
		fail_500(w, err)
		return
	}

	// Write the client request body to Git's standard input
	if _, err := io.Copy(stdin, body); err != nil {
		fail_500(w, err)
		return
	}
	stdin.Close()

	// Start writing the response
	w.Header().Add("Content-Type", fmt.Sprintf("application/x-%s-result", rpc))
	header_no_cache(w)
	w.WriteHeader(200) // Don't bother with HTTP 500 from this point on, just panic
	if _, err := io.Copy(w, stdout); err != nil {
		panic(err)
	}
	if err := cmd.Wait(); err != nil {
		panic(err)
	}
}

func pkt_line(w io.Writer, s string) error {
	_, err := fmt.Fprintf(w, "%04x%s", len(s)+4, s)
	return err
}

func pkt_flush(w io.Writer) error {
	_, err := fmt.Fprint(w, "0000")
	return err
}

func fail_500(w http.ResponseWriter, err error) {
	http.Error(w, "Internal server error", 500)
	log.Print(err)
}

func header_no_cache(w http.ResponseWriter) {
	w.Header().Add("Cache-Control", "no-cache")
}
