/*
In this file we handle git lfs objects downloads and uploads
*/

package lfs

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/filestore"
)

type object struct {
	size int64
	oid  string
}

func (l *object) Verify(fh *filestore.FileHandler) error {
	if fh.Size != l.size {
		return fmt.Errorf("LFSObject: expected size %d, wrote %d", l.size, fh.Size)
	}

	if fh.SHA256() != l.oid {
		return fmt.Errorf("LFSObject: expected sha256 %s, got %s", l.oid, fh.SHA256())
	}

	return nil
}

type uploadPreparer struct{}

func (l *uploadPreparer) Prepare(a *api.Response) (*filestore.SaveFileOpts, filestore.UploadVerifier, error) {
	opts := filestore.GetOpts(a)
	opts.TempFilePrefix = a.LfsOid

	return opts, &object{oid: a.LfsOid, size: a.LfsSize}, nil
}

func PutStore(a *api.API, h http.Handler) http.Handler {
	return filestore.BodyUploader(a, h, &uploadPreparer{})
}
