/*
In this file we handle the Git 'smart HTTP' protocol
*/

package git

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"sync"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

func GetInfoRefsHandler(a *api.API, cfg *config.Config) http.Handler {
	return repoPreAuthorizeHandler(a, func(rw http.ResponseWriter, r *http.Request, apiResponse *api.Response) {
		if apiResponse.GitalySocketPath == "" {
			handleGetInfoRefs(rw, r, apiResponse)
		} else {
			handleGetInfoRefsWithGitaly(rw, r, apiResponse, gitaly.NewClient(apiResponse.GitalySocketPath, cfg))
		}
	})
}

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

func handleGetInfoRefsWithGitaly(rw http.ResponseWriter, r *http.Request, a *api.Response, gitalyClient *gitaly.Client) {
	req := *r // Make a copy of r
	req.Header = helper.HeaderClone(r.Header)
	req.Header.Add("Gitaly-Repo-Path", a.RepoPath)
	req.Header.Add("Gitaly-GL-Id", a.GL_ID)
	req.URL.Path = path.Join(a.GitalyResourcePath, subCommand(getService(r)))
	req.URL.RawQuery = ""

	gitalyClient.Proxy.ServeHTTP(rw, &req)
}

func handleGetInfoRefs(rw http.ResponseWriter, r *http.Request, a *api.Response) {
	w := NewGitHttpResponseWriter(rw)
	// Log 0 bytes in because we ignore the request body (and there usually is none anyway).
	defer w.Log(r, 0)

	rpc := getService(r)
	if !(rpc == "git-upload-pack" || rpc == "git-receive-pack") {
		// The 'dumb' Git HTTP protocol is not supported
		http.Error(w, "Not Found", 404)
		return
	}

	// Prepare our Git subprocess
	cmd := gitCommand(a.GL_ID, "git", subCommand(rpc), "--stateless-rpc", "--advertise-refs", a.RepoPath)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		helper.Fail500(w, r, fmt.Errorf("handleGetInfoRefs: stdout: %v", err))
		return
	}
	defer stdout.Close()
	if err := cmd.Start(); err != nil {
		helper.Fail500(w, r, fmt.Errorf("handleGetInfoRefs: start %v: %v", cmd.Args, err))
		return
	}
	defer helper.CleanUpProcessGroup(cmd) // Ensure brute force subprocess clean-up

	// Start writing the response
	w.Header().Set("Content-Type", fmt.Sprintf("application/x-%s-advertisement", rpc))
	w.Header().Set("Cache-Control", "no-cache")
	w.WriteHeader(200) // Don't bother with HTTP 500 from this point on, just return
	if err := pktLine(w, fmt.Sprintf("# service=%s\n", rpc)); err != nil {
		helper.LogError(r, fmt.Errorf("handleGetInfoRefs: pktLine: %v", err))
		return
	}
	if err := pktFlush(w); err != nil {
		helper.LogError(r, fmt.Errorf("handleGetInfoRefs: pktFlush: %v", err))
		return
	}
	if _, err := io.Copy(w, stdout); err != nil {
		helper.LogError(
			r,
			&copyError{fmt.Errorf("handleGetInfoRefs: copy output of %v: %v", cmd.Args, err)},
		)
		return
	}
	if err := cmd.Wait(); err != nil {
		helper.LogError(r, fmt.Errorf("handleGetInfoRefs: wait for %v: %v", cmd.Args, err))
		return
	}
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

func handleReceivePack(action string, w *GitHttpResponseWriter, r *http.Request, a *api.Response) (writtenIn int64, err error) {
	body := r.Body
	cmd, stdin, stdout, err := setupGitCommand(action, a, w, r)

	if err != nil {
		return
	}

	defer stdout.Close()
	defer stdin.Close()
	defer helper.CleanUpProcessGroup(cmd) // Ensure brute force subprocess clean-up

	// Write the client request body to Git's standard input
	writtenIn, err = io.Copy(stdin, body)

	if err != nil {
		helper.Fail500(w, r, fmt.Errorf("handleReceivePack: write to %v: %v", cmd.Args, err))
		return
	}
	// Signal to the Git subprocess that no more data is coming
	stdin.Close()

	// It may take a while before we return and the deferred closes happen
	// so let's free up some resources already.
	r.Body.Close()

	writePostRPCHeader(w, action)

	// This io.Copy may take a long time, both for Git push and pull.
	_, err = io.Copy(w, stdout)

	if err != nil {
		helper.LogError(
			r,
			&copyError{fmt.Errorf("handleReceivePack: copy output of %v: %v", cmd.Args, err)},
		)
		return
	}

	err = cmd.Wait()

	if err != nil {
		helper.LogError(r, fmt.Errorf("handleReceivePack: wait for %v: %v", cmd.Args, err))
		return
	}

	return writtenIn, nil
}

func handleUploadPack(action string, w *GitHttpResponseWriter, r *http.Request, a *api.Response) (writtenIn int64, err error) {
	var isShallowClone bool
	var body io.Reader

	buffer := &bytes.Buffer{}
	// Only sniff on the first 4096 bytes: we assume that if we find no
	// 'deepen' message in the first 4096 bytes there won't be one later
	// either.
	_, err = io.Copy(buffer, io.LimitReader(r.Body, 4096))
	if err != nil {
		helper.Fail500(w, r, &copyError{fmt.Errorf("handleUploadPack: buffer git-upload-pack body: %v", err)})
		return
	}

	isShallowClone = scanDeepen(bytes.NewReader(buffer.Bytes()))
	body = io.MultiReader(buffer, r.Body)

	// Read out the full HTTP request body so that we can reply
	buf, err := ioutil.ReadAll(body)

	if err != nil {
		helper.Fail500(w, r, &copyError{fmt.Errorf("handleUploadPack: full buffer git-upload-pack body: %v", err)})
		return
	}

	body = ioutil.NopCloser(bytes.NewBuffer(buf))
	r.Body.Close()

	cmd, stdin, stdout, err := setupGitCommand(action, a, w, r)

	if err != nil {
		return
	}

	defer stdout.Close()
	defer stdin.Close()
	defer helper.CleanUpProcessGroup(cmd) // Ensure brute force subprocess clean-up

	stdoutError := make(chan error, 1)
	var wg sync.WaitGroup
	wg.Add(1)

	// Start writing the response
	writePostRPCHeader(w, action)

	go func() {
		defer wg.Done()

		if _, err := io.Copy(w, stdout); err != nil {
			helper.LogError(
				r,
				&copyError{fmt.Errorf("handleUploadPack: copy output of %v: %v", cmd.Args, err)},
			)
			stdoutError <- err
			return
		}
	}()

	// Write the client request body to Git's standard input
	if writtenIn, err = io.Copy(stdin, body); err != nil {
		helper.Fail500(w, r, fmt.Errorf("handleUploadPack: write to %v: %v", cmd.Args, err))
		return
	}

	// Signal to the Git subprocess that no more data is coming
	stdin.Close()
	wg.Wait()

	if len(stdoutError) > 0 {
		return
	}

	err = cmd.Wait()

	if err != nil && !(isExitError(err) && isShallowClone) {
		helper.LogError(r, fmt.Errorf("handleUploadPack: wait for %v: %v", cmd.Args, err))
		return
	}

	return writtenIn, nil
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
