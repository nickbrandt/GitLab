package upload_test

import (
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/upload"

	"github.com/stretchr/testify/require"
)

func TestPrepareWithS3Config(t *testing.T) {
	creds := config.S3Credentials{
		AwsAccessKeyID:     "test-key",
		AwsSecretAccessKey: "test-secret",
	}

	c := config.Config{
		ObjectStorageCredentials: &config.ObjectStorageCredentials{
			Provider:      "AWS",
			S3Credentials: creds,
		},
	}

	r := &api.Response{
		RemoteObject: api.RemoteObject{
			UseWorkhorseClient: true,
			ObjectStorage: &api.ObjectStorageParams{
				Provider: "AWS",
			},
		},
	}

	p := upload.NewObjectStoragePreparer(c)
	opts, v, err := p.Prepare(r)

	require.NoError(t, err)
	require.True(t, opts.ObjectStorageConfig.IsAWS())
	require.True(t, opts.UseWorkhorseClient)
	require.Equal(t, creds, opts.ObjectStorageConfig.S3Credentials)
	require.Equal(t, nil, v)
}

func TestPrepareWithNoConfig(t *testing.T) {
	c := config.Config{}
	r := &api.Response{}
	p := upload.NewObjectStoragePreparer(c)
	opts, v, err := p.Prepare(r)

	require.NoError(t, err)
	require.False(t, opts.UseWorkhorseClient)
	require.Equal(t, nil, v)
}
