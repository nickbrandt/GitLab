package main

import (
	"net/http"
)

func proxyRequest(w http.ResponseWriter, r *gitRequest) {
	upRequest, err := r.u.newUpstreamRequest(r.Request, r.Body, "")
	if err != nil {
		fail500(w, "newUpstreamRequest", err)
		return
	}

	upResponse, err := r.u.httpClient.Do(upRequest)
	if err != nil {
		fail500(w, "do upstream request", err)
		return
	}
	defer upResponse.Body.Close()

	forwardResponseToClient(w, upResponse)
}
