package git

import (
	"../helper"
	"encoding/base64"
	"fmt"
	"io"
	"net/http"
)

func SendGitBlob(w http.ResponseWriter, r *http.Request, repoPath string, blobId string) {
	blobSpec, err := base64.URLEncoding.DecodeString(blobId)
	if err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: decode commit id + path: %v", err))
		return
	}

	gitShowCmd := gitCommand("", "git", "--git-dir="+repoPath, "show", string(blobSpec))
	stdout, err := gitShowCmd.StdoutPipe()
	if err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: git show stdout: %v", err))
		return
	}
	if err := gitShowCmd.Start(); err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: start %v: %v", gitShowCmd, err))
		return
	}
	defer cleanUpProcessGroup(gitShowCmd)

	if _, err := io.Copy(w, stdout); err != nil {
		helper.LogError(fmt.Errorf("SendGitBlob: copy git show stdout: %v", err))
		return
	}
	if err := gitShowCmd.Wait(); err != nil {
		helper.LogError(fmt.Errorf("SendGitBlob: wait for git show: %v", err))
		return
	}
}
