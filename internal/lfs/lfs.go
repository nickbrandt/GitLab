/*
In this file we handle git lfs objects downloads and uploads
*/

package lfs

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/upload"
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

type uploadPreparer struct {
	credentials config.ObjectStorageCredentials
}

func NewLfsUploadPreparer(c config.Config) upload.Preparer {
	creds := c.ObjectStorageCredentials

	if creds == nil {
		creds = &config.ObjectStorageCredentials{}
	}

	return &uploadPreparer{credentials: *creds}
}

func (l *uploadPreparer) Prepare(a *api.Response) (*filestore.SaveFileOpts, upload.Verifier, error) {
	opts := filestore.GetOpts(a)
	opts.TempFilePrefix = a.LfsOid
	opts.ObjectStorageConfig.S3Credentials = l.credentials.S3Credentials

	return opts, &object{oid: a.LfsOid, size: a.LfsSize}, nil
}

func PutStore(a *api.API, h http.Handler, p upload.Preparer) http.Handler {
	return upload.BodyUploader(a, h, p)
}
