package git

import (
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
)

var (
	originalUploadPackTimeout = uploadPackTimeout
)

type fakeReader struct {
	n   int
	err error
}

func (f *fakeReader) Read(b []byte) (int, error) {
	return f.n, f.err
}

func TestUploadPackTimesOut(t *testing.T) {
	uploadPackTimeout = time.Millisecond
	defer func() { uploadPackTimeout = originalUploadPackTimeout }()

	body := &fakeReader{n: 0, err: nil}

	w := httptest.NewRecorder()
	r := httptest.NewRequest("GET", "/", body)
	a := &api.Response{}

	err := handleUploadPack(NewHttpResponseWriter(w), r, a)
	require.EqualError(t, err, "ReadAllTempfile: context deadline exceeded")

}
