package main

import (
	"net/http"
)

func (u *upstream) artifactsAuthorizeHandler(h handleFunc) handleFunc {
	return u.preAuthorizeHandler(func(w http.ResponseWriter, r *gitRequest) {
		req := r.Request
		req.Header.Set("Gitlab-Workhorse-Temp-Path", r.TempPath)
		h(w, req)
	}, "/authorize")
}
