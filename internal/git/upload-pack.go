package git

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

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

	// Start writing the response
	writePostRPCHeader(w, action)

	go func() {
		_, err := io.Copy(w, stdout)
		if err != nil {
			helper.LogError(
				r,
				&copyError{fmt.Errorf("handleUploadPack: copy output of %v: %v", cmd.Args, err)},
			)
		}
		stdoutError <- err
	}()

	// Write the client request body to Git's standard input
	if writtenIn, err = io.Copy(stdin, body); err != nil {
		helper.Fail500(w, r, fmt.Errorf("handleUploadPack: write to %v: %v", cmd.Args, err))
		return
	}

	// Signal to the Git subprocess that no more data is coming
	stdin.Close()

	if err := <-stdoutError; err != nil {
		return writtenIn, err
	}

	err = cmd.Wait()

	if err != nil && !(isExitError(err) && isShallowClone) {
		helper.LogError(r, fmt.Errorf("handleUploadPack: wait for %v: %v", cmd.Args, err))
		return
	}

	return writtenIn, nil
}
