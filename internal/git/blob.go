package git

import (
	"../helper"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
)

const SendBlobPrefix = "git-blob:"

func SendBlob(w http.ResponseWriter, r *http.Request, sendData string) {
	var params struct{ RepoPath, BlobId string }
	if err := unpackSendData(&params, sendData, SendBlobPrefix); err != nil {
		helper.Fail500(w, fmt.Errorf("SendBlob: unpack sendData: %v", err))
		return
	}

	log.Printf("SendBlob: sending %q for %q", params.BlobId, r.URL.Path)

	gitShowCmd := gitCommand("", "git", "--git-dir="+params.RepoPath, "cat-file", "blob", params.BlobId)
	stdout, err := gitShowCmd.StdoutPipe()
	if err != nil {
		helper.Fail500(w, fmt.Errorf("SendBlob: git  stdout: %v", err))
		return
	}
	if err := gitShowCmd.Start(); err != nil {
		helper.Fail500(w, fmt.Errorf("SendBlob: start %v: %v", gitShowCmd, err))
		return
	}
	defer helper.CleanUpProcessGroup(gitShowCmd)

	if _, err := io.Copy(w, stdout); err != nil {
		helper.LogError(fmt.Errorf("SendBlob: copy git cat-file stdout: %v", err))
		return
	}
	if err := gitShowCmd.Wait(); err != nil {
		helper.LogError(fmt.Errorf("SendBlob: wait for git cat-file: %v", err))
		return
	}
}

func unpackSendData(result interface{}, sendData string, prefix string) error {
	jsonBytes, err := base64.URLEncoding.DecodeString(strings.TrimPrefix(sendData, prefix))
	if err != nil {
		return err
	}
	if err := json.Unmarshal([]byte(jsonBytes), result); err != nil {
		return err
	}
	return nil
}
