package git

import (
	"../helper"
	"fmt"
	"io"
	"log"
	"net/http"
)

func SendGitBlob(w http.ResponseWriter, r *http.Request, repoPath string, blobId string) {
	log.Printf("SendGitBlob: sending %q for %q", blobId, r.URL.Path)

	gitShowCmd := gitCommand("", "git", "--git-dir="+repoPath, "show", blobId)
	stdout, err := gitShowCmd.StdoutPipe()
	if err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: git show stdout: %v", err))
		return
	}
	if err := gitShowCmd.Start(); err != nil {
		helper.Fail500(w, fmt.Errorf("SendGitBlob: start %v: %v", gitShowCmd, err))
		return
	}
	defer helper.CleanUpProcessGroup(gitShowCmd)

	if _, err := io.Copy(w, stdout); err != nil {
		helper.LogError(fmt.Errorf("SendGitBlob: copy git show stdout: %v", err))
		return
	}
	if err := gitShowCmd.Wait(); err != nil {
		helper.LogError(fmt.Errorf("SendGitBlob: wait for git show: %v", err))
		return
	}
}
