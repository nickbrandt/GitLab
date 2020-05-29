package upload

import (
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/filestore"
)

type ObjectStoragePreparer struct {
	credentials config.ObjectStorageCredentials
}

func NewObjectStoragePreparer(c config.Config) Preparer {
	creds := c.ObjectStorageCredentials

	if creds == nil {
		creds = &config.ObjectStorageCredentials{}
	}

	return &ObjectStoragePreparer{credentials: *creds}
}

func (p *ObjectStoragePreparer) Prepare(a *api.Response) (*filestore.SaveFileOpts, Verifier, error) {
	opts := filestore.GetOpts(a)
	opts.ObjectStorageConfig.S3Credentials = p.credentials.S3Credentials

	return opts, nil, nil
}
