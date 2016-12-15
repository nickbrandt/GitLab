package upload

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"os"
	"path"
	"strings"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

// These methods are allowed to have thread-unsafe implementations.
type MultipartFormProcessor interface {
	ProcessFile(formName, fileName string, writer *multipart.Writer) error
	ProcessField(formName string, writer *multipart.Writer) error
	Finalize() error
}

func rewriteFormFilesFromMultipart(r *http.Request, writer *multipart.Writer, tempPath string, filter MultipartFormProcessor) (cleanup func(), err error) {
	// Create multipart reader
	reader, err := r.MultipartReader()
	if err != nil {
		if err == http.ErrNotMultipart {
			// We want to be able to recognize http.ErrNotMultipart elsewhere so no fmt.Errorf
			return nil, http.ErrNotMultipart
		}
		return nil, fmt.Errorf("get multipart reader: %v", err)
	}

	var directories []string

	cleanup = func() {
		for _, dir := range directories {
			os.RemoveAll(dir)
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
			if strings.Contains(filename, "/") || filename == "." || filename == ".." {
				return cleanup, fmt.Errorf("illegal filename: %q", filename)
			}

			// Create temporary directory where the uploaded file will be stored
			if err := os.MkdirAll(tempPath, 0700); err != nil {
				return cleanup, fmt.Errorf("mkdir for tempfile: %v", err)
			}

			tempDir, err := ioutil.TempDir(tempPath, "multipart-")
			if err != nil {
				return cleanup, fmt.Errorf("create tempdir: %v", err)
			}
			directories = append(directories, tempDir)

			file, err := os.OpenFile(path.Join(tempDir, filename), os.O_WRONLY|os.O_CREATE, 0600)
			if err != nil {
				return cleanup, fmt.Errorf("rewriteFormFilesFromMultipart: temp file: %v", err)
			}
			defer file.Close()

			// Add file entry
			writer.WriteField(name+".path", file.Name())
			writer.WriteField(name+".name", filename)

			_, err = io.Copy(file, p)
			if err != nil {
				return cleanup, fmt.Errorf("copy from multipart to tempfile: %v", err)
			}

			file.Close()

			if err := filter.ProcessFile(name, file.Name(), writer); err != nil {
				return cleanup, err
			}
		} else {
			np, err := writer.CreatePart(p.Header)
			if err != nil {
				return cleanup, fmt.Errorf("create multipart field: %v", err)
			}

			_, err = io.Copy(np, p)
			if err != nil {
				return cleanup, fmt.Errorf("duplicate multipart field: %v", err)
			}

			if err := filter.ProcessField(name, writer); err != nil {
				return cleanup, fmt.Errorf("process multipart field: %v", err)
			}
		}
	}
	return cleanup, nil
}

func HandleFileUploads(w http.ResponseWriter, r *http.Request, h http.Handler, tempPath string, filter MultipartFormProcessor) {
	if tempPath == "" {
		helper.Fail500(w, r, fmt.Errorf("handleFileUploads: tempPath empty"))
		return
	}

	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	defer writer.Close()

	// Rewrite multipart form data
	cleanup, err := rewriteFormFilesFromMultipart(r, writer, tempPath, filter)
	if err != nil {
		if err == http.ErrNotMultipart {
			h.ServeHTTP(w, r)
		} else {
			helper.Fail500(w, r, fmt.Errorf("handleFileUploads: extract files from multipart: %v", err))
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

	if err := filter.Finalize(); err != nil {
		helper.Fail500(w, r, fmt.Errorf("handleFileUploads: Finalize: %v", err))
		return
	}

	// Proxy the request
	h.ServeHTTP(w, r)
}
