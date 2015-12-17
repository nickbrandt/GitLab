package main

import (
	"net/http"
)

func (u *upstream) artifactsAuthorizeHandler(h httpHandleFunc) httpHandleFunc {
	return u.preAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *authorizationResponse) {
		r.Header.Set(tempPathHeader, a.TempPath)
		h(w, r)
	}, "/authorize")
}
