package main

import (
	"net/http"
)

func (api *API) artifactsAuthorizeHandler(h httpHandleFunc) httpHandleFunc {
	return api.preAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *authorizationResponse) {
		r.Header.Set(tempPathHeader, a.TempPath)
		h(w, r)
	}, "/authorize")
}
