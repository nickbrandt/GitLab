package git

import (
	"fmt"
	"net/http"

	"github.com/golang/protobuf/jsonpb"

	"gitlab.com/gitlab-org/gitaly-proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/senddata"
)

type diff struct{ senddata.Prefix }
type diffParams struct {
	GitalyServer   gitaly.Server
	RawDiffRequest string
}

var SendDiff = &diff{"git-diff:"}

func (d *diff) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params diffParams
	if err := d.Unpack(&params, sendData); err != nil {
		helper.Fail500(w, r, fmt.Errorf("SendDiff: unpack sendData: %v", err))
		return
	}

	request := &gitalypb.RawDiffRequest{}
	if err := jsonpb.UnmarshalString(params.RawDiffRequest, request); err != nil {
		helper.Fail500(w, r, fmt.Errorf("diff.RawDiff: %v", err))
		return
	}

	diffClient, err := gitaly.NewDiffClient(params.GitalyServer)
	if err != nil {
		helper.Fail500(w, r, fmt.Errorf("diff.RawDiff: %v", err))
		return
	}

	if err := diffClient.SendRawDiff(r.Context(), w, request); err != nil {
		helper.LogError(
			r,
			&copyError{fmt.Errorf("diff.RawDiff: request=%v, err=%v", request, err)},
		)
		return
	}
}
