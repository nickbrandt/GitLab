package git

import (
	"fmt"
	"io"
	"log"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/senddata"
)

type diff struct{ senddata.Prefix }
type diffParams struct {
	RepoPath string
	ShaFrom  string
	ShaTo    string
}

var SendDiff = &diff{"git-diff:"}

func (d *diff) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params diffParams
	if err := d.Unpack(&params, sendData); err != nil {
		helper.Fail500(w, fmt.Errorf("SendDiff: unpack sendData: %v", err))
		return
	}

	log.Printf("SendDiff: sending diff between %q and %q for %q", params.ShaFrom, params.ShaTo, r.URL.Path)

	gitShowCmd := gitCommand("", "git", "--git-dir="+params.RepoPath, "diff", params.ShaFrom, params.ShaTo)
	stdout, err := gitShowCmd.StdoutPipe()
	if err != nil {
		helper.Fail500(w, fmt.Errorf("SendDiff: git diff %q %q stdout: %v", params.ShaFrom, params.ShaTo, err))
		return
	}
	if err := gitShowCmd.Start(); err != nil {
		helper.Fail500(w, fmt.Errorf("SendDiff: git diff %q %q stdout: %v", params.ShaFrom, params.ShaTo, err))
		return
	}
	defer helper.CleanUpProcessGroup(gitShowCmd)

	if _, err := io.Copy(w, stdout); err != nil {
		helper.LogError(fmt.Errorf("SendDiff: git diff %q %q stdout: %v", err))
		return
	}
	if err := gitShowCmd.Wait(); err != nil {
		helper.LogError(fmt.Errorf("SendDiff: git diff %q %q stdout: %v", err))
		return
	}
}
