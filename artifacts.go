package main

import (
	"net/http"
)

func (u *upstream) artifactsAuthorizeHandler(h httpHandleFunc) httpHandleFunc {
	return u.preAuthorizeHandler(func(w http.ResponseWriter, r *gitRequest) {
		req := r.Request
		req.Header.Set(tempPathHeader, r.TempPath)
		h(w, req)
	}, "/authorize")
}
