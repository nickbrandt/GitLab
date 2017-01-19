package git

import (
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

func handleReceivePack(w *GitHttpResponseWriter, r *http.Request, a *api.Response) (writtenIn int64, err error) {
	body := r.Body
	action := getService(r)
	cmd, stdin, stdout, err := setupGitCommand(action, a)

	if err != nil {
		fail500(w)
		return writtenIn, fmt.Errorf("setupGitCommand: %v", err)
	}

	defer stdout.Close()
	defer stdin.Close()
	defer helper.CleanUpProcessGroup(cmd) // Ensure brute force subprocess clean-up

	// Write the client request body to Git's standard input
	writtenIn, err = io.Copy(stdin, body)

	if err != nil {
		fail500(w)
		return writtenIn, fmt.Errorf("write to %v: %v", cmd.Args, err)
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
		return writtenIn, &copyError{fmt.Errorf("copy output of %v: %v", cmd.Args, err)}
	}

	err = cmd.Wait()

	if err != nil {
		return writtenIn, fmt.Errorf("wait for %v: %v", cmd.Args, err)
	}

	return writtenIn, nil
}
