package config

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestLoadObjectStorageConfig(t *testing.T) {
	config := `
[object_storage]
enabled = true
provider = "AWS"

[object_storage.s3]
aws_access_key_id = "minio"
aws_secret_access_key = "gdk-minio"
`
	tmpFile, err := ioutil.TempFile(os.TempDir(), "test-")
	require.NoError(t, err)

	defer os.Remove(tmpFile.Name())

	_, err = tmpFile.Write([]byte(config))
	require.NoError(t, err)

	cfg, err := LoadConfig(tmpFile.Name())
	require.NoError(t, err)

	require.NotNil(t, cfg.ObjectStorageCredentials, "Expected object storage credentials")

	expected := ObjectStorageCredentials{
		Provider: "AWS",
		S3Credentials: S3Credentials{
			AwsAccessKeyID:     "minio",
			AwsSecretAccessKey: "gdk-minio",
		},
	}

	require.Equal(t, expected, *cfg.ObjectStorageCredentials)
}
