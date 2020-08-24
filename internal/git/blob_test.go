package git

import (
	"net/http/httptest"
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
)

func TestSetBlobHeaders(t *testing.T) {
	w := httptest.NewRecorder()
	w.Header().Set("Set-Cookie", "gitlab_cookie=123456")

	setBlobHeaders(w)

	testhelper.RequireAbsentResponseWriterHeader(t, w, "Set-Cookie")
}
