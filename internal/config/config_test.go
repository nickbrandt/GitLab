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
provider = "AWS"

[object_storage.s3]
aws_access_key_id = "minio"
aws_secret_access_key = "gdk-minio"
`

	tmpFile, cfg := loadTempConfig(t, config)
	defer os.Remove(tmpFile.Name())

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

func TestRegisterGoCloudURLOpeners(t *testing.T) {
	config := `
[object_storage]
provider = "AzureRM"

[object_storage.azurerm]
azure_storage_account_name = "azuretester"
azure_storage_access_key = "deadbeef"
`
	tmpFile, cfg := loadTempConfig(t, config)
	defer os.Remove(tmpFile.Name())

	require.NotNil(t, cfg.ObjectStorageCredentials, "Expected object storage credentials")

	expected := ObjectStorageCredentials{
		Provider: "AzureRM",
		AzureCredentials: AzureCredentials{
			AccountName: "azuretester",
			AccountKey:  "deadbeef",
		},
	}

	require.Equal(t, expected, *cfg.ObjectStorageCredentials)
	require.Nil(t, cfg.ObjectStorageConfig.URLMux)

	err := cfg.RegisterGoCloudURLOpeners()
	require.NoError(t, err)
	require.NotNil(t, cfg.ObjectStorageConfig.URLMux)

	require.True(t, cfg.ObjectStorageConfig.URLMux.ValidBucketScheme("azblob"))
	require.Equal(t, []string{"azblob"}, cfg.ObjectStorageConfig.URLMux.BucketSchemes())
}

func loadTempConfig(t *testing.T, config string) (f *os.File, cfg *Config) {
	tmpFile, err := ioutil.TempFile(os.TempDir(), "test-")
	require.NoError(t, err)

	_, err = tmpFile.Write([]byte(config))
	require.NoError(t, err)

	cfg, err = LoadConfig(tmpFile.Name())
	require.NoError(t, err)

	return tmpFile, cfg
}
