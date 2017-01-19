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

func ReceivePack(a *api.API) http.Handler {
	return postRPCHandler(a, "handleReceivePack", handleReceivePack)
}

func UploadPack(a *api.API) http.Handler {
	return postRPCHandler(a, "handleUploadPack", handleUploadPack)
}

func postRPCHandler(a *api.API, name string, handler func(*GitHttpResponseWriter, *http.Request, *api.Response) (int64, error)) http.Handler {
	return repoPreAuthorizeHandler(a, func(rw http.ResponseWriter, r *http.Request, ar *api.Response) {
		var writtenIn int64
		var err error

		w := NewGitHttpResponseWriter(rw)
		defer func() {
			w.Log(r, writtenIn)
		}()

		writtenIn, err = handler(w, r, ar)
		if err != nil {
			helper.LogError(r, fmt.Errorf("%s: %v", name, err))
		}
	})
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

func setupGitCommand(action string, a *api.Response, options ...string) (cmd *exec.Cmd, stdin io.WriteCloser, stdout io.ReadCloser, err error) {
	// Don't leak pipes when we return early after an error
	defer func() {
		if err == nil {
			return
		}
		if stdin != nil {
			stdin.Close()
		}
		if stdout != nil {
			stdout.Close()
		}
	}()

	// Prepare our Git subprocess
	args := []string{subCommand(action), "--stateless-rpc"}
	args = append(args, options...)
	args = append(args, a.RepoPath)
	cmd = gitCommand(a.GL_ID, "git", args...)
	stdout, err = cmd.StdoutPipe()
	if err != nil {
		return nil, nil, nil, fmt.Errorf("stdout pipe: %v", err)
	}

	stdin, err = cmd.StdinPipe()
	if err != nil {
		return nil, nil, nil, fmt.Errorf("stdin pipe: %v", err)
	}

	if err = cmd.Start(); err != nil {
		return nil, nil, nil, fmt.Errorf("start %v: %v", cmd.Args, err)
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
