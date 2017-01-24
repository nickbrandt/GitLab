package git

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

func GetInfoRefsHandler(a *api.API) http.Handler {
	return repoPreAuthorizeHandler(a, handleGetInfoRefs)
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

	var err error
	if a.GitalySocketPath == "" {
		err = handleGetInfoRefsLocally(w, a, rpc)
	} else {
		err = handleGetInfoRefsWithGitaly(w, a, rpc)
	}

	if err != nil {
		helper.LogError(r, fmt.Errorf("handleGetInfoRefs: %v", err))
	}
}

func handleGetInfoRefsLocally(w http.ResponseWriter, a *api.Response, rpc string) error {
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

func handleGetInfoRefsWithGitaly(w http.ResponseWriter, a *api.Response, rpc string) error {
	smarthttp, err := gitaly.NewSmartHTTPClient(a.GitalySocketPath)
	if err != nil {
		return fmt.Errorf("GetInfoRefsHandler: %v", err)
	}

	infoRefsResponseWriter, err := smarthttp.InfoRefsResponseWriterTo(a.RepoPath, rpc)
	if err != nil {
		return fmt.Errorf("GetInfoRefsHandler: %v", err)
	}

	if _, err = infoRefsResponseWriter.WriteTo(w); err != nil {
		return fmt.Errorf("handleGetInfoRefsWithGitaly: Error receiving response from server: %v", err)
	}

	return nil
}
