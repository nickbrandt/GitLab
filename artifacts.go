package main

import (
	"net/http"
)

func artifactsAuthorizeHandler(api *API, h httpHandleFunc) httpHandleFunc {
	return api.preAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *apiResponse) {
		r.Header.Set(tempPathHeader, a.TempPath)
		h(w, r)
	}, "/authorize")
}
