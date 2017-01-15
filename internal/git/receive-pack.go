package git

import (
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

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
