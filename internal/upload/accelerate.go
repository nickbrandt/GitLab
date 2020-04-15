package upload

import (
	"net/http"

	jwt "github.com/dgrijalva/jwt-go"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/filestore"
)

const RewrittenFieldsHeader = "Gitlab-Workhorse-Multipart-Fields"

type MultipartClaims struct {
	RewrittenFields map[string]string `json:"rewritten_fields"`
	jwt.StandardClaims
}

func Accelerate(rails filestore.PreAuthorizer, h http.Handler) http.Handler {
	return rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		s := &SavedFileTracker{Request: r}
		HandleFileUploads(w, r, h, a, s)
	}, "/authorize")
}
