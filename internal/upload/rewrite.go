package upload

import (
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"os"
	"path"
	"strings"

	"github.com/prometheus/client_golang/prometheus"
)

var (
	multipartUploadRequests = prometheus.NewCounter(
		prometheus.CounterOpts{

			Name: "gitlab_workhorse_multipart_upload_requests",
			Help: "How many multipart upload requests have been processed by gitlab-workhorse.",
		},
	)

	multipartFileUploadBytes = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_multipart_upload_bytes",
			Help: "How many disk bytes of multipart file parts have been written by gitlab-workhorse.",
		},
	)

	multipartFiles = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_multipart_upload_files",
			Help: "How many multipart file parts have been processed by gitlab-workhorse.",
		},
	)
)

func init() {
	prometheus.MustRegister(multipartUploadRequests)
	prometheus.MustRegister(multipartFileUploadBytes)
	prometheus.MustRegister(multipartFiles)
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

	multipartUploadRequests.Inc()

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
			multipartFiles.Inc()

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

			written, err := io.Copy(file, p)
			if err != nil {
				return cleanup, fmt.Errorf("copy from multipart to tempfile: %v", err)
			}
			multipartFileUploadBytes.Add(float64(written))

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
