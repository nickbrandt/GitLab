/*
The xSendFile middleware transparently sends static files in HTTP responses
via the X-Sendfile mechanism. All that is needed in the Rails code is the
'send_file' method.
*/

package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

func handleSendFile(w http.ResponseWriter, r *gitRequest) {
	upRequest, err := r.u.newUpstreamRequest(r.Request, r.Body, "")
	if err != nil {
		fail500(w, fmt.Errorf("handleSendFile: newUpstreamRequest: %v", err))
		return
	}

	upRequest.Header.Set("X-Sendfile-Type", "X-Sendfile")
	upResponse, err := r.u.httpClient.Do(upRequest)
	r.Body.Close()
	if err != nil {
		fail500(w, fmt.Errorf("handleSendfile: do upstream request: %v", err))
		return
	}

	defer upResponse.Body.Close()
	// Get X-Sendfile
	sendfile := upResponse.Header.Get("X-Sendfile")
	upResponse.Header.Del("X-Sendfile")

	// Copy headers from Rails upResponse
	for k, v := range upResponse.Header {
		w.Header()[k] = v
	}

	// Use accelerated file serving
	if sendfile == "" {
		// Copy request body otherwise
		w.WriteHeader(upResponse.StatusCode)

		// Copy body from Rails upResponse
		if _, err := io.Copy(w, upResponse.Body); err != nil {
			fail500(w, fmt.Errorf("handleSendFile: copy upstream response: %v", err))
		}
		return
	}

	log.Printf("Serving file %q", sendfile)
	upResponse.Body.Close()
	content, err := os.Open(sendfile)
	if err != nil {
		fail500(w, fmt.Errorf("handleSendile: open sendfile: %v", err))
		return
	}
	defer content.Close()

	fi, err := content.Stat()
	if err != nil {
		fail500(w, fmt.Errorf("handleSendfile: get mtime: %v", err))
		return
	}
	http.ServeContent(w, r.Request, "", fi.ModTime(), content)
}
