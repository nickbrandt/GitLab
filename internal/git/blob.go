package git

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitaly-proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/senddata"
)

type blob struct{ senddata.Prefix }
type blobParams struct {
	GitalyServer   gitaly.Server
	GetBlobRequest gitalypb.GetBlobRequest
}

var SendBlob = &blob{"git-blob:"}

func (b *blob) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params blobParams
	if err := b.Unpack(&params, sendData); err != nil {
		helper.Fail500(w, r, fmt.Errorf("SendBlob: unpack sendData: %v", err))
		return
	}

	blobClient, err := gitaly.NewBlobClient(params.GitalyServer)
	if err != nil {
		helper.Fail500(w, r, fmt.Errorf("blob.GetBlob: %v", err))
		return
	}

	if err := blobClient.SendBlob(r.Context(), w, &params.GetBlobRequest); err != nil {
		helper.Fail500(w, r, fmt.Errorf("blob.GetBlob: %v", err))
		return
	}
}
