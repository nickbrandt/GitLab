package upload

import (
	"../api"
	"net/http"
)

func Artifacts(myAPI *api.API, h http.Handler) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		r.Header.Set(tempPathHeader, a.TempPath)
		handleFileUploads(h).ServeHTTP(w, r)
	}, "/authorize")
}
