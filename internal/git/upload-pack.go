package git

import (
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

// Will not return a non-nil error after the response body has been
// written to.
func handleUploadPack(w *GitHttpResponseWriter, r *http.Request, a *api.Response) error {
	// The body will consist almost entirely of 'have XXX' and 'want XXX'
	// lines; these are about 50 bytes long. With a limit of 10MB the client
	// can send over 200,000 have/want lines.
	buffer, err := helper.ReadAllTempfile(io.LimitReader(r.Body, 10*1024*1024))
	if err != nil {
		return fmt.Errorf("ReadAllTempfile: %v", err)
	}
	defer buffer.Close()
	r.Body.Close()

	isShallowClone := scanDeepen(buffer)
	if _, err := buffer.Seek(0, 0); err != nil {
		return fmt.Errorf("seek tempfile: %v", err)
	}

	action := getService(r)
	writePostRPCHeader(w, action)

	cmd, err := startGitCommand(a, buffer, w, action)
	if err != nil {
		return fmt.Errorf("startGitCommand: %v", err)
	}
	defer helper.CleanUpProcessGroup(cmd)

	if err := cmd.Wait(); err != nil && !(isExitError(err) && isShallowClone) {
		helper.LogError(r, fmt.Errorf("wait for %v: %v", cmd.Args, err))
		// Return nil because the response body has been written to already.
		return nil
	}

	return nil
}
