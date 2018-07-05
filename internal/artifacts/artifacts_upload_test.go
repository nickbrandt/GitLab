package artifacts

import (
	"archive/zip"
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/badgateway"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/zipartifacts"
)

const (
	MetadataHeaderKey     = "Metadata-Status"
	MetadataHeaderPresent = "present"
	MetadataHeaderMissing = "missing"
)

func testArtifactsUploadServer(t *testing.T, authResponse api.Response, bodyProcessor func(w http.ResponseWriter, r *http.Request)) *httptest.Server {
	mux := http.NewServeMux()
	mux.HandleFunc("/url/path/authorize", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			t.Fatal("Expected POST request")
		}

		w.Header().Set("Content-Type", api.ResponseContentType)

		data, err := json.Marshal(&authResponse)
		if err != nil {
			t.Fatal("Expected to marshal")
		}
		w.Write(data)
	})
	mux.HandleFunc("/url/path", func(w http.ResponseWriter, r *http.Request) {
		opts := filestore.GetOpts(&authResponse)

		if r.Method != "POST" {
			t.Fatal("Expected POST request")
		}
		if opts.IsLocal() {
			if r.FormValue("file.path") == "" {
				t.Fatal("Expected file to be present")
				return
			}

			_, err := ioutil.ReadFile(r.FormValue("file.path"))
			if err != nil {
				t.Fatal("Expected file to be readable")
				return
			}
		} else if opts.IsRemote() {
			if r.FormValue("file.remote_url") == "" {
				t.Fatal("Expected file to be remote accessible")
				return
			}
		}

		if r.FormValue("metadata.path") != "" {
			metadata, err := ioutil.ReadFile(r.FormValue("metadata.path"))
			if err != nil {
				t.Fatal("Expected metadata to be readable")
				return
			}
			gz, err := gzip.NewReader(bytes.NewReader(metadata))
			if err != nil {
				t.Fatal("Expected metadata to be valid gzip")
				return
			}
			defer gz.Close()
			metadata, err = ioutil.ReadAll(gz)
			if err != nil {
				t.Fatal("Expected metadata to be valid")
				return
			}
			if !bytes.HasPrefix(metadata, []byte(zipartifacts.MetadataHeaderPrefix+zipartifacts.MetadataHeader)) {
				t.Fatal("Expected metadata to be of valid format")
				return
			}

			w.Header().Set(MetadataHeaderKey, MetadataHeaderPresent)

		} else {
			w.Header().Set(MetadataHeaderKey, MetadataHeaderMissing)
		}

		w.WriteHeader(http.StatusOK)

		if bodyProcessor != nil {
			bodyProcessor(w, r)
		}
	})
	return testhelper.TestServerWithHandler(nil, mux.ServeHTTP)
}

func testUploadArtifacts(contentType string, body io.Reader, t *testing.T, ts *httptest.Server) *httptest.ResponseRecorder {
	httpRequest, err := http.NewRequest("POST", ts.URL+"/url/path", body)
	if err != nil {
		t.Fatal(err)
	}
	httpRequest.Header.Set("Content-Type", contentType)
	response := httptest.NewRecorder()
	parsedURL := helper.URLMustParse(ts.URL)
	roundTripper := badgateway.TestRoundTripper(parsedURL)
	testhelper.ConfigureSecret()
	apiClient := api.NewAPI(parsedURL, "123", roundTripper)
	proxyClient := proxy.NewProxy(parsedURL, "123", roundTripper)
	UploadArtifacts(apiClient, proxyClient).ServeHTTP(response, httpRequest)
	return response
}

func TestUploadHandlerAddingMetadata(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempPath)

	ts := testArtifactsUploadServer(t, api.Response{TempPath: tempPath}, nil)
	defer ts.Close()

	var buffer bytes.Buffer
	writer := multipart.NewWriter(&buffer)
	file, err := writer.CreateFormFile("file", "my.file")
	if err != nil {
		t.Fatal(err)
	}
	archive := zip.NewWriter(file)
	defer archive.Close()

	fileInArchive, err := archive.Create("test.file")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Fprint(fileInArchive, "test")
	archive.Close()
	writer.Close()

	response := testUploadArtifacts(writer.FormDataContentType(), &buffer, t, ts)
	testhelper.AssertResponseCode(t, response, http.StatusOK)
	testhelper.AssertResponseHeader(t, response, MetadataHeaderKey, MetadataHeaderPresent)
}

func TestUploadHandlerForUnsupportedArchive(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempPath)

	ts := testArtifactsUploadServer(t, api.Response{TempPath: tempPath}, nil)
	defer ts.Close()

	var buffer bytes.Buffer
	writer := multipart.NewWriter(&buffer)
	file, err := writer.CreateFormFile("file", "my.file")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Fprint(file, "test")
	writer.Close()

	response := testUploadArtifacts(writer.FormDataContentType(), &buffer, t, ts)
	testhelper.AssertResponseCode(t, response, http.StatusOK)
	testhelper.AssertResponseHeader(t, response, MetadataHeaderKey, MetadataHeaderMissing)
}

func TestUploadHandlerForMultipleFiles(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempPath)

	ts := testArtifactsUploadServer(t, api.Response{TempPath: tempPath}, nil)
	defer ts.Close()

	var buffer bytes.Buffer
	writer := multipart.NewWriter(&buffer)
	file, err := writer.CreateFormFile("file", "my.file")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Fprint(file, "test")

	file, err = writer.CreateFormFile("file", "my.file")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Fprint(file, "test")
	writer.Close()

	response := testUploadArtifacts(writer.FormDataContentType(), &buffer, t, ts)
	testhelper.AssertResponseCode(t, response, http.StatusInternalServerError)
}

func TestUploadFormProcessing(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempPath)

	ts := testArtifactsUploadServer(t, api.Response{TempPath: tempPath}, nil)
	defer ts.Close()

	var buffer bytes.Buffer
	writer := multipart.NewWriter(&buffer)
	file, err := writer.CreateFormFile("metadata", "my.file")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Fprint(file, "test")
	writer.Close()

	response := testUploadArtifacts(writer.FormDataContentType(), &buffer, t, ts)
	testhelper.AssertResponseCode(t, response, http.StatusInternalServerError)
}
