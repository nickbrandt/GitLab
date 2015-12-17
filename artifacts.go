package main

func (u *upstream) artifactsAuthorizeHandler(handleFunc serviceHandleFunc) serviceHandleFunc {
	return u.preAuthorizeHandler(handleFunc, "/authorize")
}
