package git

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

// Will not return a non-nil error after the response body has been
// written to.
func handleReceivePack(w *GitHttpResponseWriter, r *http.Request, a *api.Response) error {
	action := getService(r)
	writePostRPCHeader(w, action)

	cmd, err := startGitCommand(a, r.Body, w, action)
	if err != nil {
		return fmt.Errorf("startGitCommand: %v", err)
	}
	defer helper.CleanUpProcessGroup(cmd)

	if err := cmd.Wait(); err != nil {
		helper.LogError(r, fmt.Errorf("wait for %v: %v", cmd.Args, err))
		// Return nil because the response body has been written to already.
		return nil
	}

	return nil
}
