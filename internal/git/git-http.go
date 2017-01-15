/*
In this file we handle the Git 'smart HTTP' protocol
*/

package git

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

func PostRPC(a *api.API) http.Handler {
	return repoPreAuthorizeHandler(a, handlePostRPC)
}

func looksLikeRepo(p string) bool {
	// If /path/to/foo.git/objects exists then let's assume it is a valid Git
	// repository.
	if _, err := os.Stat(path.Join(p, "objects")); err != nil {
		log.Print(err)
		return false
	}
	return true
}

func repoPreAuthorizeHandler(myAPI *api.API, handleFunc api.HandleFunc) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		if a.RepoPath == "" {
			helper.Fail500(w, r, fmt.Errorf("repoPreAuthorizeHandler: RepoPath empty"))
			return
		}

		if !looksLikeRepo(a.RepoPath) {
			http.Error(w, "Not Found", 404)
			return
		}

		handleFunc(w, r, a)
	}, "")
}

func handlePostRPC(rw http.ResponseWriter, r *http.Request, a *api.Response) {
	var writtenIn int64

	w := NewGitHttpResponseWriter(rw)
	defer func() {
		w.Log(r, writtenIn)
	}()

	action := getService(r)
	if !(action == "git-upload-pack" || action == "git-receive-pack") {
		// The 'dumb' Git HTTP protocol is not supported
		helper.Fail500(w, r, fmt.Errorf("handlePostRPC: unsupported action: %s", r.URL.Path))
		return
	}

	if action == "git-receive-pack" {
		writtenIn, _ = handleReceivePack(action, w, r, a)
	} else {
		writtenIn, _ = handleUploadPack(action, w, r, a)
	}
}

func setupGitCommand(action string, a *api.Response, w *GitHttpResponseWriter, r *http.Request) (cmd *exec.Cmd, stdin io.WriteCloser, stdout io.ReadCloser, err error) {
	// Prepare our Git subprocess
	cmd = gitCommand(a.GL_ID, "git", subCommand(action), "--stateless-rpc", a.RepoPath)
	stdout, err = cmd.StdoutPipe()
	if err != nil {
		helper.Fail500(w, r, fmt.Errorf("setupGitCommand: stdout: %v", err))
		return nil, nil, nil, err
	}

	stdin, err = cmd.StdinPipe()
	if err != nil {
		helper.Fail500(w, r, fmt.Errorf("setupGitCommand: stdin: %v", err))
		return nil, nil, nil, err
	}

	if err = cmd.Start(); err != nil {
		helper.Fail500(w, r, fmt.Errorf("setupGitCommand: start %v: %v", cmd.Args, err))
		return nil, nil, nil, err
	}

	return cmd, stdin, stdout, nil
}

func writePostRPCHeader(w http.ResponseWriter, action string) {
	w.Header().Set("Content-Type", fmt.Sprintf("application/x-%s-result", action))
	w.Header().Set("Cache-Control", "no-cache")
	w.WriteHeader(200) // Don't bother with HTTP 500 from this point on, just return
}

func getService(r *http.Request) string {
	if r.Method == "GET" {
		return r.URL.Query().Get("service")
	}
	return filepath.Base(r.URL.Path)
}

func isExitError(err error) bool {
	_, ok := err.(*exec.ExitError)
	return ok
}

func subCommand(rpc string) string {
	return strings.TrimPrefix(rpc, "git-")
}
