package upstream

import (
	"../api"
	"net/http"
)

func artifactsAuthorizeHandler(myAPI *api.API, h http.HandlerFunc) http.HandlerFunc {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		r.Header.Set(tempPathHeader, a.TempPath)
		h(w, r)
	}, "/authorize")
}
