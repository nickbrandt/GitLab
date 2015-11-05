/*
The xSendFile middleware transparently sends static files in HTTP responses
via the X-Sendfile mechanism. All that is needed in the Rails code is the
'send_file' method.
*/

package main

import (
	"io"
	"log"
	"net/http"
	"os"
)

func xSendFile(u *upstream, w http.ResponseWriter, r *http.Request, _ func(http.ResponseWriter, *gitRequest, string), _ string) {
	upRequest, err := u.newUpstreamRequest(r)
	if err != nil {
		fail500(w, "newUpstreamRequest", err)
		return
	}

	upRequest.Header.Set("X-Sendfile-Type", "X-Sendfile")
	upResponse, err := u.httpClient.Do(upRequest)
	if err != nil {
		fail500(w, "do upstream request", err)
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
			fail500(w, "Couldn't finalize X-File download request.", err)
		}
		return
	}

	log.Printf("Serving file %q", sendfile)
	upResponse.Body.Close()
	content, err := os.Open(sendfile)
	if err != nil {
		fail500(w, "open sendfile", err)
		return
	}
	defer content.Close()

	fi, err := content.Stat()
	if err != nil {
		fail500(w, "xSendFile get mtime", err)
		return
	}
	http.ServeContent(w, r, "", fi.ModTime(), content)
}
