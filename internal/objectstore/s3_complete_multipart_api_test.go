package objectstore

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestMultipartUploadETag(t *testing.T) {
	cmu := CompleteMultipartUpload{
		Part: []*completeMultipartUploadPart{
			{PartNumber: 1, ETag: "550cf6b6e60f65a0e3104a26e70fea42"},
			{PartNumber: 2, ETag: "920b914bca0a70780b40881b8f376135"},
			{PartNumber: 3, ETag: "175719e13d23c021058bc7376696f26f"},
		},
	}
	expectedETag := "1dc6ab8f946f699770f14f46a8739671-3"

	etag, err := cmu.BuildMultipartUploadETag()
	require.NoError(t, err)
	require.Equal(t, expectedETag, etag)
}
