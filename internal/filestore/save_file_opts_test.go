package filestore_test

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/filestore"
)

func TestSaveFileOptsLocalAndRemote(t *testing.T) {
	tests := []struct {
		name          string
		localTempPath string
		presignedPut  string
		partSize      int64
		isLocal       bool
		isRemote      bool
		isMultipart   bool
	}{
		{
			name:          "Only LocalTempPath",
			localTempPath: "/tmp",
			isLocal:       true,
		},
		{
			name:          "Both paths",
			localTempPath: "/tmp",
			presignedPut:  "http://example.com",
			isLocal:       true,
			isRemote:      true,
		},
		{
			name: "No paths",
		},
		{
			name:         "Only remoteUrl",
			presignedPut: "http://example.com",
			isRemote:     true,
		},
		{
			name:        "Multipart",
			partSize:    10,
			isRemote:    true,
			isMultipart: true,
		},
		{
			name:          "Multipart and Local",
			partSize:      10,
			localTempPath: "/tmp",
			isRemote:      true,
			isMultipart:   true,
			isLocal:       true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {

			assert := assert.New(t)

			opts := filestore.SaveFileOpts{
				LocalTempPath: test.localTempPath,
				PresignedPut:  test.presignedPut,
				PartSize:      test.partSize,
			}

			assert.Equal(test.isLocal, opts.IsLocal(), "IsLocal() mismatch")
			assert.Equal(test.isRemote, opts.IsRemote(), "IsRemote() mismatch")
			assert.Equal(test.isMultipart, opts.IsMultipart(), "IsMultipart() mismatch")
		})
	}
}

func TestGetOpts(t *testing.T) {
	tests := []struct {
		name             string
		multipart        *api.MultipartUploadParams
		customPutHeaders bool
		putHeaders       map[string]string
	}{
		{
			name: "Single upload",
		}, {
			name: "Multipart upload",
			multipart: &api.MultipartUploadParams{
				PartSize:    10,
				CompleteURL: "http://complete",
				AbortURL:    "http://abort",
				PartURLs:    []string{"http://part1", "http://part2"},
			},
		},
		{
			name:             "Single upload with custom content type",
			customPutHeaders: true,
			putHeaders:       map[string]string{"Content-Type": "image/jpeg"},
		}, {
			name: "Multipart upload with custom content type",
			multipart: &api.MultipartUploadParams{
				PartSize:    10,
				CompleteURL: "http://complete",
				AbortURL:    "http://abort",
				PartURLs:    []string{"http://part1", "http://part2"},
			},
			customPutHeaders: true,
			putHeaders:       map[string]string{"Content-Type": "image/jpeg"},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {

			assert := assert.New(t)
			apiResponse := &api.Response{
				TempPath: "/tmp",
				RemoteObject: api.RemoteObject{
					Timeout:          10,
					ID:               "id",
					GetURL:           "http://get",
					StoreURL:         "http://store",
					DeleteURL:        "http://delete",
					MultipartUpload:  test.multipart,
					CustomPutHeaders: test.customPutHeaders,
					PutHeaders:       test.putHeaders,
				},
			}
			deadline := time.Now().Add(time.Duration(apiResponse.RemoteObject.Timeout) * time.Second)
			opts := filestore.GetOpts(apiResponse)

			assert.Equal(apiResponse.TempPath, opts.LocalTempPath)
			assert.WithinDuration(deadline, opts.Deadline, time.Second)
			assert.Equal(apiResponse.RemoteObject.ID, opts.RemoteID)
			assert.Equal(apiResponse.RemoteObject.GetURL, opts.RemoteURL)
			assert.Equal(apiResponse.RemoteObject.StoreURL, opts.PresignedPut)
			assert.Equal(apiResponse.RemoteObject.DeleteURL, opts.PresignedDelete)
			if test.customPutHeaders {
				assert.Equal(opts.PutHeaders, apiResponse.RemoteObject.PutHeaders)
			} else {
				assert.Equal(opts.PutHeaders, map[string]string{"Content-Type": "application/octet-stream"})
			}

			if test.multipart == nil {
				assert.False(opts.IsMultipart())
				assert.Empty(opts.PresignedCompleteMultipart)
				assert.Empty(opts.PresignedAbortMultipart)
				assert.Zero(opts.PartSize)
				assert.Empty(opts.PresignedParts)
			} else {
				assert.True(opts.IsMultipart())
				assert.Equal(test.multipart.CompleteURL, opts.PresignedCompleteMultipart)
				assert.Equal(test.multipart.AbortURL, opts.PresignedAbortMultipart)
				assert.Equal(test.multipart.PartSize, opts.PartSize)
				assert.Equal(test.multipart.PartURLs, opts.PresignedParts)
			}
		})
	}
}

func TestGetOptsDefaultTimeout(t *testing.T) {
	assert := assert.New(t)

	deadline := time.Now().Add(filestore.DefaultObjectStoreTimeout)
	opts := filestore.GetOpts(&api.Response{})

	assert.WithinDuration(deadline, opts.Deadline, time.Minute)
}

func TestUseWorkhorseClientEnabled(t *testing.T) {
	cfg := filestore.ObjectStorageConfig{
		Provider: "AWS",
		S3Config: config.S3Config{
			Bucket: "test-bucket",
			Region: "test-region",
		},
		S3Credentials: config.S3Credentials{
			AwsAccessKeyID:     "test-key",
			AwsSecretAccessKey: "test-secret",
		},
	}

	missingCfg := cfg
	missingCfg.S3Credentials = config.S3Credentials{}

	iamConfig := missingCfg
	iamConfig.S3Config.UseIamProfile = true

	tests := []struct {
		name                string
		UseWorkhorseClient  bool
		remoteTempObjectID  string
		objectStorageConfig filestore.ObjectStorageConfig
		expected            bool
	}{
		{
			name:                "all direct access settings used",
			UseWorkhorseClient:  true,
			remoteTempObjectID:  "test-object",
			objectStorageConfig: cfg,
			expected:            true,
		},
		{
			name:                "missing AWS credentials",
			UseWorkhorseClient:  true,
			remoteTempObjectID:  "test-object",
			objectStorageConfig: missingCfg,
			expected:            false,
		},
		{
			name:                "direct access disabled",
			UseWorkhorseClient:  false,
			remoteTempObjectID:  "test-object",
			objectStorageConfig: cfg,
			expected:            false,
		},
		{
			name:                "with IAM instance profile",
			UseWorkhorseClient:  true,
			remoteTempObjectID:  "test-object",
			objectStorageConfig: iamConfig,
			expected:            true,
		},
		{
			name:                "missing remote temp object ID",
			UseWorkhorseClient:  true,
			remoteTempObjectID:  "",
			objectStorageConfig: cfg,
			expected:            false,
		},
		{
			name:               "missing S3 config",
			UseWorkhorseClient: true,
			remoteTempObjectID: "test-object",
			expected:           false,
		},
		{
			name:               "missing S3 bucket",
			UseWorkhorseClient: true,
			remoteTempObjectID: "test-object",
			objectStorageConfig: filestore.ObjectStorageConfig{
				Provider: "AWS",
				S3Config: config.S3Config{},
			},
			expected: false,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {

			apiResponse := &api.Response{
				TempPath: "/tmp",
				RemoteObject: api.RemoteObject{
					Timeout:            10,
					ID:                 "id",
					UseWorkhorseClient: test.UseWorkhorseClient,
					RemoteTempObjectID: test.remoteTempObjectID,
				},
			}
			deadline := time.Now().Add(time.Duration(apiResponse.RemoteObject.Timeout) * time.Second)
			opts := filestore.GetOpts(apiResponse)
			opts.ObjectStorageConfig = test.objectStorageConfig

			require.Equal(t, apiResponse.TempPath, opts.LocalTempPath)
			require.WithinDuration(t, deadline, opts.Deadline, time.Second)
			require.Equal(t, apiResponse.RemoteObject.ID, opts.RemoteID)
			require.Equal(t, apiResponse.RemoteObject.UseWorkhorseClient, opts.UseWorkhorseClient)
			require.Equal(t, test.expected, opts.UseWorkhorseClientEnabled())
		})
	}
}
