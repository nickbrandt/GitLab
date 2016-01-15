package git

import (
	"../helper"
	"bufio"
	"encoding/base64"
	"fmt"
	"io"
	"net/http"
)

const blobLine = `blob
`

func SendGitBlob(w http.ResponseWriter, r *http.Request, repoPath string, blobId string) {
	blobSpec, err := base64.URLEncoding.DecodeString(blobId)
	if err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: decode commit id + path: %v", err))
		return
	}

	catFileCmd := gitCommand("", "git", "--git-dir="+repoPath, "cat-file", "--batch=%(objecttype)")
	catFileStdin, err := catFileCmd.StdinPipe()
	if err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: git cat-file stdin: %v", err))
		return
	}

	catFileStdout, err := catFileCmd.StdoutPipe()
	if err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: git cat-file stdout: %v", err))
		return
	}

	if err := catFileCmd.Start(); err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: start %v: %v", catFileCmd, err))
		return
	}
	defer cleanUpProcessGroup(catFileCmd)
	if _, err := fmt.Fprintf(catFileStdin, "%s\n", blobSpec); err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: send command to git cat-file: %v", err))
		return
	}
	if err := catFileStdin.Close(); err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: close git cat-file stdin: %v", err))
		return
	}
	out := bufio.NewReader(catFileStdout)
	if response, err := out.ReadString('\n'); err != nil || response != blobLine {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: git cat-file returned %q, error: %v", response, err))
		return
	}

	if _, err := io.Copy(w, catFileStdout); err != nil {
		helper.LogError(fmt.Errorf("SendGitBlob: copy git cat-file stdout: %v", err))
		return
	}
	if err := catFileCmd.Wait(); err != nil {
		helper.LogError(fmt.Errorf("SendGitBlob: wait for git cat-file: %v", err))
		return
	}
}
