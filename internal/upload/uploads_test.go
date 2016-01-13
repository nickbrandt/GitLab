package upload

import (
	"../helper"
	"../proxy"
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"regexp"
	"strings"
	"testing"
)

var nilHandler = http.HandlerFunc(func(http.ResponseWriter, *http.Request) {})

func TestUploadTempPathRequirement(t *testing.T) {
	response := httptest.NewRecorder()
	request := &http.Request{}
	handleFileUploads(nilHandler).ServeHTTP(response, request)
	helper.AssertResponseCode(t, response, 500)
}

func TestUploadHandlerForwardingRawData(t *testing.T) {
	ts := helper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "PATCH" {
			t.Fatal("Expected PATCH request")
		}

		var body bytes.Buffer
		io.Copy(&body, r.Body)
		if body.String() != "REQUEST" {
			t.Fatal("Expected REQUEST in request body")
		}

		w.WriteHeader(202)
		fmt.Fprint(w, "RESPONSE")
	})
	defer ts.Close()

	httpRequest, err := http.NewRequest("PATCH", ts.URL+"/url/path", bytes.NewBufferString("REQUEST"))
	if err != nil {
		t.Fatal(err)
	}

	tempPath, err := ioutil.TempDir("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempPath)

	response := httptest.NewRecorder()

	httpRequest.Header.Set(tempPathHeader, tempPath)

	handleFileUploads(proxy.NewProxy(helper.URLMustParse(ts.URL), "123", nil)).ServeHTTP(response, httpRequest)
	helper.AssertResponseCode(t, response, 202)
	if response.Body.String() != "RESPONSE" {
		t.Fatal("Expected RESPONSE in response body")
	}
}

func TestUploadHandlerRewritingMultiPartData(t *testing.T) {
	var filePath string

	tempPath, err := ioutil.TempDir("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempPath)

	ts := helper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "PUT" {
			t.Fatal("Expected PUT request")
		}

		err := r.ParseMultipartForm(100000)
		if err != nil {
			t.Fatal(err)
		}

		if len(r.MultipartForm.Value) != 3 {
			t.Fatal("Expected to receive exactly 3 values")
		}

		if len(r.MultipartForm.File) != 0 {
			t.Fatal("Expected to not receive any files")
		}

		if r.FormValue("token") != "test" {
			t.Fatal("Expected to receive token")
		}

		if r.FormValue("file.name") != "my.file" {
			t.Fatal("Expected to receive a filename")
		}

		filePath = r.FormValue("file.path")

		if !strings.HasPrefix(r.FormValue("file.path"), tempPath) {
			t.Fatal("Expected to the file to be in tempPath")
		}

		w.WriteHeader(202)
		fmt.Fprint(w, "RESPONSE")
	})

	var buffer bytes.Buffer

	writer := multipart.NewWriter(&buffer)
	writer.WriteField("token", "test")
	file, err := writer.CreateFormFile("file", "my.file")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Fprint(file, "test")
	writer.Close()

	httpRequest, err := http.NewRequest("PUT", ts.URL+"/url/path", nil)
	if err != nil {
		t.Fatal(err)
	}

	httpRequest.Body = ioutil.NopCloser(&buffer)
	httpRequest.ContentLength = int64(buffer.Len())
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
	httpRequest.Header.Set(tempPathHeader, tempPath)
	response := httptest.NewRecorder()

	handleFileUploads(proxy.NewProxy(helper.URLMustParse(ts.URL), "123", nil)).ServeHTTP(response, httpRequest)
	helper.AssertResponseCode(t, response, 202)

	if _, err := os.Stat(filePath); !os.IsNotExist(err) {
		t.Fatal("expected the file to be deleted")
	}
}
