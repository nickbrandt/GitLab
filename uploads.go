package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"os"
)

func rewriteFormFilesFromMultipart(r *gitRequest, writer *multipart.Writer) (cleanup func(), err error) {
	// Create multipart reader
	reader, err := r.MultipartReader()
	if err != nil {
		return nil, err
	}

	var files []string

	cleanup = func() {
		for _, file := range files {
			os.Remove(file)
		}
	}

	// Execute cleanup in case of failure
	defer func() {
		if err != nil {
			cleanup()
		}
	}()

	for {
		p, err := reader.NextPart()
		if err == io.EOF {
			break
		}

		name := p.FormName()
		if name == "" {
			continue
		}

		// Copy form field
		if filename := p.FileName(); filename != "" {
			// Create temporary directory where the uploaded file will be stored
			if err := os.MkdirAll(r.TempPath, 0700); err != nil {
				return cleanup, err
			}

			// Create temporary file in path returned by Authorization filter
			file, err := ioutil.TempFile(r.TempPath, "upload_")
			if err != nil {
				return cleanup, err
			}
			defer file.Close()

			// Add file entry
			writer.WriteField(name+".path", file.Name())
			writer.WriteField(name+".name", filename)
			files = append(files, file.Name())

			_, err = io.Copy(file, p)
			file.Close()
			if err != nil {
				return cleanup, err
			}
		} else {
			np, err := writer.CreatePart(p.Header)
			if err != nil {
				return cleanup, err
			}

			_, err = io.Copy(np, p)
			if err != nil {
				return cleanup, err
			}
		}
	}
	return cleanup, nil
}

func handleFileUploads(w http.ResponseWriter, r *gitRequest) {
	if r.TempPath == "" {
		fail500(w, errors.New("handleFileUploads: TempPath empty"))
		return
	}

	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	defer writer.Close()

	// Rewrite multipart form data
	cleanup, err := rewriteFormFilesFromMultipart(r, writer)
	if err != nil {
		if err == http.ErrNotMultipart {
			proxyRequest(w, r)
		} else {
			fail500(w, fmt.Errorf("handleFileUploads: extract files from multipart: %v", err))
		}
		return
	}

	if cleanup != nil {
		defer cleanup()
	}

	// Close writer
	writer.Close()

	// Create request
	upstreamRequest, err := r.u.newUpstreamRequest(r.Request, nil, "")
	if err != nil {
		fail500(w, fmt.Errorf("handleFileUploads: newUpstreamRequest: %v", err))
		return
	}

	// Set multipart form data
	upstreamRequest.Body = ioutil.NopCloser(&body)
	upstreamRequest.ContentLength = int64(body.Len())
	upstreamRequest.Header.Set("Content-Type", writer.FormDataContentType())

	// Forward request to backend
	upstreamResponse, err := r.u.httpClient.Do(upstreamRequest)
	if err != nil {
		fail500(w, fmt.Errorf("handleFileUploads: do request %v: %v", upstreamRequest.URL.Path, err))
		return
	}
	defer upstreamResponse.Body.Close()

	forwardResponseToClient(w, upstreamResponse)
}
