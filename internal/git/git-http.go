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
	"sync"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

func ReceivePack(a *api.API) http.Handler {
	return postRPCHandler(a, "handleReceivePack", handleReceivePack)
}

func UploadPack(a *api.API) http.Handler {
	return postRPCHandler(a, "handleUploadPack", handleUploadPack)
}

func postRPCHandler(a *api.API, name string, handler func(*GitHttpResponseWriter, *http.Request, *api.Response) error) http.Handler {
	return repoPreAuthorizeHandler(a, func(rw http.ResponseWriter, r *http.Request, ar *api.Response) {
		cr := &countReadCloser{ReadCloser: r.Body}
		r.Body = cr

		w := NewGitHttpResponseWriter(rw)
		defer func() {
			w.Log(r, cr.Count())
		}()

		if err := handler(w, r, ar); err != nil {
			helper.Fail500(w, r, fmt.Errorf("%s: %v", name, err))
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

func startGitCommand(a *api.Response, stdin io.Reader, stdout io.Writer, action string, options ...string) (cmd *exec.Cmd, err error) {
	// Prepare our Git subprocess
	args := []string{subCommand(action), "--stateless-rpc"}
	args = append(args, options...)
	args = append(args, a.RepoPath)
	cmd = gitCommand(a.GL_ID, "git", args...)
	cmd.Stdin = stdin
	cmd.Stdout = stdout

	if err = cmd.Start(); err != nil {
		return nil, fmt.Errorf("start %v: %v", cmd.Args, err)
	}

	return cmd, nil
}

func writePostRPCHeader(w http.ResponseWriter, action string) {
	w.Header().Set("Content-Type", fmt.Sprintf("application/x-%s-result", action))
	w.Header().Set("Cache-Control", "no-cache")
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

type countReadCloser struct {
	n int64
	io.ReadCloser
	sync.Mutex
}

func (c *countReadCloser) Read(p []byte) (n int, err error) {
	n, err = c.ReadCloser.Read(p)

	c.Lock()
	defer c.Unlock()
	c.n += int64(n)

	return n, err
}

func (c *countReadCloser) Count() int64 {
	c.Lock()
	defer c.Unlock()
	return c.n
}
