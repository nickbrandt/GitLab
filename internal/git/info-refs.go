package git

import (
	"fmt"
	"net/http"
	"path"

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

	w.Header().Set("Content-Type", fmt.Sprintf("application/x-%s-advertisement", rpc))
	w.Header().Set("Cache-Control", "no-cache")

	if err := writeBody(w, a, rpc); err != nil {
		helper.LogError(r, fmt.Errorf("handleGetInfoRefs: %v", err))
	}
}

func writeBody(w http.ResponseWriter, a *api.Response, rpc string) error {
	if err := pktLine(w, fmt.Sprintf("# service=%s\n", rpc)); err != nil {
		return fmt.Errorf("pktLine: %v", err)
	}
	if err := pktFlush(w); err != nil {
		return fmt.Errorf("pktFlush: %v", err)
	}

	cmd, err := startGitCommand(a, nil, w, rpc, "--advertise-refs")
	if err != nil {
		return fmt.Errorf("startGitCommand: %v", err)
	}
	defer helper.CleanUpProcessGroup(cmd) // Ensure brute force subprocess clean-up

	if err := cmd.Wait(); err != nil {
		return fmt.Errorf("wait for %v: %v", cmd.Args, err)
	}

	return nil
}
