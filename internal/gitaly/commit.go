package gitaly

import (
	"fmt"
	"io"
	"net/http"
	"strconv"

	pb "gitlab.com/gitlab-org/gitaly-proto/go"
	"gitlab.com/gitlab-org/gitaly/streamio"

	"golang.org/x/net/context"
)

type CommitClient struct {
	pb.CommitClient
}

func (client *CommitClient) SendBlob(w http.ResponseWriter, request *pb.TreeEntryRequest) error {
	ctx, cancelFunc := context.WithCancel(context.Background())
	defer cancelFunc()

	c, err := client.TreeEntry(ctx, request)
	if err != nil {
		return fmt.Errorf("rpc failed: %v", err)
	}

	firstResponseReceived := false
	rr := streamio.NewReader(func() ([]byte, error) {
		resp, err := c.Recv()

		if !firstResponseReceived && err == nil {
			firstResponseReceived = true
			w.Header().Set("Content-Length", strconv.FormatInt(resp.GetSize(), 10))
		}

		return resp.GetData(), err
	})

	if _, err := io.Copy(w, rr); err != nil {
		return fmt.Errorf("copy rpc data: %v", err)
	}

	return nil
}
