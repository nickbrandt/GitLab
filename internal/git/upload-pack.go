package git

import (
	"bytes"
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

func handleUploadPack(w *GitHttpResponseWriter, r *http.Request, a *api.Response) (writtenIn int64, err error) {
	buffer := &bytes.Buffer{}
	// Only sniff on the first 4096 bytes: we assume that if we find no
	// 'deepen' message in the first 4096 bytes there won't be one later
	// either.
	_, err = io.Copy(buffer, io.LimitReader(r.Body, 4096))
	if err != nil {
		fail500(w)
		return writtenIn, &copyError{fmt.Errorf("buffer git-upload-pack body: %v", err)}
	}
	isShallowClone := scanDeepen(bytes.NewReader(buffer.Bytes()))

	// We must drain the request body before writing the response, to avoid
	// upsetting NGINX.
	remainder, err := helper.ReadAllTempfile(r.Body)
	if err != nil {
		fail500(w)
		return writtenIn, fmt.Errorf("ReadAllTempfile: %v", err)
	}
	defer remainder.Close()

	body := io.MultiReader(buffer, remainder)
	r.Body.Close()

	action := getService(r)
	cmd, stdin, stdout, err := setupGitCommand(action, a)

	if err != nil {
		fail500(w)
		return writtenIn, fmt.Errorf("setupGitCommand: %v", err)
	}

	defer stdout.Close()
	defer stdin.Close()
	defer helper.CleanUpProcessGroup(cmd) // Ensure brute force subprocess clean-up

	stdoutError := make(chan error, 1)
	go func() {
		writePostRPCHeader(w, action)
		// Start reading from stdout already to avoid blocking while writing to
		// stdin below.
		_, err := io.Copy(w, stdout)
		// This error may be lost if some other error prevents us from <-ing on this channel.
		stdoutError <- err
	}()

	// Write the client request body to Git's standard input
	if writtenIn, err = io.Copy(stdin, body); err != nil {
		fail500(w)
		return writtenIn, fmt.Errorf("write to %v: %v", cmd.Args, err)
	}

	// Signal to the Git subprocess that no more data is coming
	stdin.Close()

	if err := <-stdoutError; err != nil {
		return writtenIn, &copyError{fmt.Errorf("copy output of %v: %v", cmd.Args, err)}
	}

	err = cmd.Wait()

	if err != nil && !(isExitError(err) && isShallowClone) {
		return writtenIn, fmt.Errorf("wait for %v: %v", cmd.Args, err)
	}

	return writtenIn, nil
}

func fail500(w http.ResponseWriter) {
	helper.Fail500(w, nil, nil)
}
