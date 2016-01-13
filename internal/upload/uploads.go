package upload

import (
	"../helper"
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"os"
)

const tempPathHeader = "Gitlab-Workhorse-Temp-Path"

type MultipartFormFilter interface {
	FilterFile(formName, fileName string, writer *multipart.Writer) error
	FilterField(formName string, writer *multipart.Writer) error
}

func rewriteFormFilesFromMultipart(r *http.Request, writer *multipart.Writer, tempPath string, filter MultipartFormFilter) (cleanup func(), err error) {
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
			if err := os.MkdirAll(tempPath, 0700); err != nil {
				return cleanup, err
			}

			// Create temporary file in path returned by Authorization filter
			file, err := ioutil.TempFile(tempPath, "upload_")
			if err != nil {
				return cleanup, err
			}
			defer file.Close()

			// Add file entry
			writer.WriteField(name+".path", file.Name())
			writer.WriteField(name+".name", filename)
			files = append(files, file.Name())

			_, err = io.Copy(file, p)
			if err != nil {
				return cleanup, err
			}

			file.Close()

			if filter != nil {
				err = filter.FilterFile(name, filename, writer)
				if err != nil {
					return cleanup, err
				}
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

			if filter != nil {
				err = filter.FilterField(name, writer)
				if err != nil {
					return cleanup, err
				}
			}
		}
	}
	return cleanup, nil
}

func HandleFileUploads(w http.ResponseWriter, r *http.Request, h http.Handler, tempPath string, filter MultipartFormFilter) {
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	defer writer.Close()

	// Rewrite multipart form data
	cleanup, err := rewriteFormFilesFromMultipart(r, writer, tempPath, filter)
	if err != nil {
		if err == http.ErrNotMultipart {
			h.ServeHTTP(w, r)
		} else {
			helper.Fail500(w, fmt.Errorf("handleFileUploads: extract files from multipart: %v", err))
		}
		return
	}

	if cleanup != nil {
		defer cleanup()
	}

	// Close writer
	writer.Close()

	// Hijack the request
	r.Body = ioutil.NopCloser(&body)
	r.ContentLength = int64(body.Len())
	r.Header.Set("Content-Type", writer.FormDataContentType())

	// Proxy the request
	h.ServeHTTP(w, r)
}
