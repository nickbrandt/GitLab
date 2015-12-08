package main

import (
	"fmt"
	"net/http"
)

func proxyRequest(w http.ResponseWriter, r *gitRequest) {
	upRequest, err := r.u.newUpstreamRequest(r.Request, r.Body, "")
	if err != nil {
		fail500(w, fmt.Errorf("proxyRequest: newUpstreamRequest: %v", err))
		return
	}

	upResponse, err := r.u.httpClient.Do(upRequest)
	if err != nil {
		fail500(w, fmt.Errorf("proxyRequest: do %v: %v", upRequest.URL.Path, err))
		return
	}
	defer upResponse.Body.Close()

	forwardResponseToClient(w, upResponse)
}
