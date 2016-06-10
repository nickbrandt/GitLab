package git

import (
	"fmt"
	"io"
	"log"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/senddata"
)

type patch struct{ senddata.Prefix }
type patchParams struct {
	RepoPath string
	ShaFrom  string
	ShaTo    string
}

var SendPatch = &diff{"git-format-patch:"}

func (p *patch) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params patchParams
	if err := p.Unpack(&params, sendData); err != nil {
		helper.Fail500(w, fmt.Errorf("SendPatch: unpack sendData: %v", err))
		return
	}

	log.Printf("SendPatch: sending patch between %q and %q for %q", params.ShaFrom, params.ShaTo, r.URL.Path)

	gitRange := fmt.Sprintf("%v...%v", params.ShaFrom, params.ShaTo)
	gitPatchCmd := gitCommand("", "git", "--git-dir="+params.RepoPath, "format-patch", gitRange, "--stdout")

	stdout, err := gitPatchCmd.StdoutPipe()
	if err != nil {
		helper.Fail500(w, fmt.Errorf("SendPatch: create stdout pipe: %v", err))
		return
	}

	if err := gitPatchCmd.Start(); err != nil {
		helper.Fail500(w, fmt.Errorf("SendPatch: start %v: %v", gitPatchCmd, err))
		return
	}
	defer helper.CleanUpProcessGroup(gitPatchCmd)

	w.Header().Del("Content-Length")
	if _, err := io.Copy(w, stdout); err != nil {
		helper.LogError(fmt.Errorf("SendPatch: copy %v stdout: %v", gitPatchCmd, err))
		return
	}
	if err := gitPatchCmd.Wait(); err != nil {
		helper.LogError(fmt.Errorf("SendPatch: wait for %v: %v", gitPatchCmd, err))
		return
	}
}
