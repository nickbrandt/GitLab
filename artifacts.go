package main

func artifactsAuthorizeHandler(handleFunc serviceHandleFunc) serviceHandleFunc {
	return preAuthorizeHandler(handleFunc, "/authorize")
}
