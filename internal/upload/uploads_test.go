package upload

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"regexp"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/objectstore/test"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/upstream/roundtripper"
)

var nilHandler = http.HandlerFunc(func(http.ResponseWriter, *http.Request) {})

type testFormProcessor struct{}

func (a *testFormProcessor) ProcessFile(ctx context.Context, formName string, file *filestore.FileHandler, writer *multipart.Writer) error {
	return nil
}

func (a *testFormProcessor) ProcessField(ctx context.Context, formName string, writer *multipart.Writer) error {
	if formName != "token" && !strings.HasPrefix(formName, "file.") && !strings.HasPrefix(formName, "other.") {
		return fmt.Errorf("illegal field: %v", formName)
	}
	return nil
}

func (a *testFormProcessor) Finalize(ctx context.Context) error {
	return nil
}

func (a *testFormProcessor) Name() string {
	return ""
}

func TestUploadTempPathRequirement(t *testing.T) {
	response := httptest.NewRecorder()
	request, err := http.NewRequest("", "", nil)
	if err != nil {
		t.Fatal(err)
	}
	apiResponse := &api.Response{}
	preparer := &DefaultPreparer{}
	opts, _, err := preparer.Prepare(apiResponse)
	require.NoError(t, err)

	HandleFileUploads(response, request, nilHandler, apiResponse, &testFormProcessor{}, opts)
	testhelper.AssertResponseCode(t, response, 500)
}

func TestUploadHandlerForwardingRawData(t *testing.T) {
	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
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

	handler := newProxy(ts.URL)
	apiResponse := &api.Response{TempPath: tempPath}
	preparer := &DefaultPreparer{}
	opts, _, err := preparer.Prepare(apiResponse)
	require.NoError(t, err)

	HandleFileUploads(response, httpRequest, handler, apiResponse, nil, opts)

	testhelper.AssertResponseCode(t, response, 202)
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

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "PUT" {
			t.Fatal("Expected PUT request")
		}

		err := r.ParseMultipartForm(100000)
		if err != nil {
			t.Fatal(err)
		}

		if len(r.MultipartForm.File) != 0 {
			t.Error("Expected to not receive any files")
		}

		if r.FormValue("token") != "test" {
			t.Error("Expected to receive token")
		}

		if r.FormValue("file.name") != "my.file" {
			t.Error("Expected to receive a filename")
		}

		filePath = r.FormValue("file.path")
		if !strings.HasPrefix(filePath, tempPath) {
			t.Error("Expected to the file to be in tempPath")
		}

		if r.FormValue("file.remote_url") != "" {
			t.Error("Expected to receive empty remote_url")
		}

		if r.FormValue("file.remote_id") != "" {
			t.Error("Expected to receive empty remote_id")
		}

		if r.FormValue("file.size") != "4" {
			t.Error("Expected to receive the file size")
		}

		hashes := map[string]string{
			"md5":    "098f6bcd4621d373cade4e832627b4f6",
			"sha1":   "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
			"sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
			"sha512": "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff",
		}

		for algo, hash := range hashes {
			if r.FormValue("file."+algo) != hash {
				t.Errorf("Expected to receive file %s hash", algo)
			}
		}

		if valueCnt := len(r.MultipartForm.Value); valueCnt != 11 {
			t.Fatal("Expected to receive exactly 11 values but got", valueCnt)
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

	ctx, cancel := context.WithCancel(context.Background())
	httpRequest = httpRequest.WithContext(ctx)
	httpRequest.Body = ioutil.NopCloser(&buffer)
	httpRequest.ContentLength = int64(buffer.Len())
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
	response := httptest.NewRecorder()

	handler := newProxy(ts.URL)

	apiResponse := &api.Response{TempPath: tempPath}
	preparer := &DefaultPreparer{}
	opts, _, err := preparer.Prepare(apiResponse)
	require.NoError(t, err)

	HandleFileUploads(response, httpRequest, handler, apiResponse, &testFormProcessor{}, opts)
	testhelper.AssertResponseCode(t, response, 202)

	cancel() // this will trigger an async cleanup
	waitUntilDeleted(t, filePath)
}

func TestUploadHandlerDetectingInjectedMultiPartData(t *testing.T) {
	var filePath string

	tempPath, err := ioutil.TempDir("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempPath)

	tests := []struct {
		name     string
		field    string
		response int
	}{
		{
			name:     "injected file.path",
			field:    "file.path",
			response: 400,
		},
		{
			name:     "injected file.remote_id",
			field:    "file.remote_id",
			response: 400,
		},
		{
			name:     "field with other prefix",
			field:    "other.path",
			response: 202,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
				if r.Method != "PUT" {
					t.Fatal("Expected PUT request")
				}

				w.WriteHeader(202)
				fmt.Fprint(w, "RESPONSE")
			})

			var buffer bytes.Buffer

			writer := multipart.NewWriter(&buffer)
			file, err := writer.CreateFormFile("file", "my.file")
			if err != nil {
				t.Fatal(err)
			}
			fmt.Fprint(file, "test")

			writer.WriteField(test.field, "value")
			writer.Close()

			httpRequest, err := http.NewRequest("PUT", ts.URL+"/url/path", &buffer)
			if err != nil {
				t.Fatal(err)
			}

			ctx, cancel := context.WithCancel(context.Background())
			httpRequest = httpRequest.WithContext(ctx)
			httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
			response := httptest.NewRecorder()

			handler := newProxy(ts.URL)
			apiResponse := &api.Response{TempPath: tempPath}
			preparer := &DefaultPreparer{}
			opts, _, err := preparer.Prepare(apiResponse)
			require.NoError(t, err)

			HandleFileUploads(response, httpRequest, handler, apiResponse, &testFormProcessor{}, opts)
			testhelper.AssertResponseCode(t, response, test.response)

			cancel() // this will trigger an async cleanup
			waitUntilDeleted(t, filePath)
		})
	}
}

func TestUploadProcessingField(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempPath)

	var buffer bytes.Buffer

	writer := multipart.NewWriter(&buffer)
	writer.WriteField("token2", "test")
	writer.Close()

	httpRequest, err := http.NewRequest("PUT", "/url/path", &buffer)
	if err != nil {
		t.Fatal(err)
	}
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

	response := httptest.NewRecorder()
	apiResponse := &api.Response{TempPath: tempPath}
	preparer := &DefaultPreparer{}
	opts, _, err := preparer.Prepare(apiResponse)
	require.NoError(t, err)

	HandleFileUploads(response, httpRequest, nilHandler, apiResponse, &testFormProcessor{}, opts)

	testhelper.AssertResponseCode(t, response, 500)
}

func TestUploadProcessingFile(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempPath)

	_, testServer := test.StartObjectStore()
	defer testServer.Close()

	storeUrl := testServer.URL + test.ObjectPath

	tests := []struct {
		name    string
		preauth api.Response
	}{
		{
			name:    "FileStore Upload",
			preauth: api.Response{TempPath: tempPath},
		},
		{
			name:    "ObjectStore Upload",
			preauth: api.Response{RemoteObject: api.RemoteObject{StoreURL: storeUrl}},
		},
		{
			name: "ObjectStore and FileStore Upload",
			preauth: api.Response{
				TempPath:     tempPath,
				RemoteObject: api.RemoteObject{StoreURL: storeUrl},
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			var buffer bytes.Buffer
			writer := multipart.NewWriter(&buffer)
			file, err := writer.CreateFormFile("file", "my.file")
			if err != nil {
				t.Fatal(err)
			}
			fmt.Fprint(file, "test")
			writer.Close()

			httpRequest, err := http.NewRequest("PUT", "/url/path", &buffer)
			if err != nil {
				t.Fatal(err)
			}
			httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

			response := httptest.NewRecorder()
			apiResponse := &api.Response{TempPath: tempPath}
			preparer := &DefaultPreparer{}
			opts, _, err := preparer.Prepare(apiResponse)
			require.NoError(t, err)

			HandleFileUploads(response, httpRequest, nilHandler, apiResponse, &testFormProcessor{}, opts)

			testhelper.AssertResponseCode(t, response, 200)
		})
	}

}

func TestInvalidFileNames(t *testing.T) {
	testhelper.ConfigureSecret()

	tempPath, err := ioutil.TempDir("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempPath)

	for _, testCase := range []struct {
		filename string
		code     int
	}{
		{"foobar", 200}, // sanity check for test setup below
		{"foo/bar", 500},
		{"/../../foobar", 500},
		{".", 500},
		{"..", 500},
	} {
		buffer := &bytes.Buffer{}

		writer := multipart.NewWriter(buffer)
		file, err := writer.CreateFormFile("file", testCase.filename)
		if err != nil {
			t.Fatal(err)
		}
		fmt.Fprint(file, "test")
		writer.Close()

		httpRequest, err := http.NewRequest("POST", "/example", buffer)
		if err != nil {
			t.Fatal(err)
		}
		httpRequest.Header.Set("Content-Type", writer.FormDataContentType())

		response := httptest.NewRecorder()
		apiResponse := &api.Response{TempPath: tempPath}
		preparer := &DefaultPreparer{}
		opts, _, err := preparer.Prepare(apiResponse)
		require.NoError(t, err)

		HandleFileUploads(response, httpRequest, nilHandler, apiResponse, &SavedFileTracker{Request: httpRequest}, opts)
		testhelper.AssertResponseCode(t, response, testCase.code)
	}
}

func TestUploadHandlerRemovingExif(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)
	defer os.RemoveAll(tempPath)

	var buffer bytes.Buffer

	content, err := ioutil.ReadFile("exif/testdata/sample_exif.jpg")
	require.NoError(t, err)

	writer := multipart.NewWriter(&buffer)
	file, err := writer.CreateFormFile("file", "test.jpg")
	require.NoError(t, err)

	_, err = file.Write(content)
	require.NoError(t, err)

	err = writer.Close()
	require.NoError(t, err)

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(100000)
		require.NoError(t, err)

		size, err := strconv.Atoi(r.FormValue("file.size"))
		require.NoError(t, err)
		require.True(t, size < len(content), "Expected the file to be smaller after removal of exif")
		require.True(t, size > 0, "Expected to receive not empty file")

		w.WriteHeader(200)
		fmt.Fprint(w, "RESPONSE")
	})
	defer ts.Close()

	httpRequest, err := http.NewRequest("POST", ts.URL+"/url/path", &buffer)
	require.NoError(t, err)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	httpRequest = httpRequest.WithContext(ctx)
	httpRequest.ContentLength = int64(buffer.Len())
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
	response := httptest.NewRecorder()

	handler := newProxy(ts.URL)
	apiResponse := &api.Response{TempPath: tempPath}
	preparer := &DefaultPreparer{}
	opts, _, err := preparer.Prepare(apiResponse)
	require.NoError(t, err)

	HandleFileUploads(response, httpRequest, handler, apiResponse, &testFormProcessor{}, opts)
	testhelper.AssertResponseCode(t, response, 200)
}

func TestUploadHandlerRemovingInvalidExif(t *testing.T) {
	tempPath, err := ioutil.TempDir("", "uploads")
	require.NoError(t, err)
	defer os.RemoveAll(tempPath)

	var buffer bytes.Buffer

	writer := multipart.NewWriter(&buffer)
	file, err := writer.CreateFormFile("file", "test.jpg")
	require.NoError(t, err)

	fmt.Fprint(file, "this is not valid image data")
	err = writer.Close()
	require.NoError(t, err)

	ts := testhelper.TestServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(100000)
		require.Error(t, err)
	})
	defer ts.Close()

	httpRequest, err := http.NewRequest("POST", ts.URL+"/url/path", &buffer)
	require.NoError(t, err)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	httpRequest = httpRequest.WithContext(ctx)
	httpRequest.ContentLength = int64(buffer.Len())
	httpRequest.Header.Set("Content-Type", writer.FormDataContentType())
	response := httptest.NewRecorder()

	handler := newProxy(ts.URL)
	apiResponse := &api.Response{TempPath: tempPath}
	preparer := &DefaultPreparer{}
	opts, _, err := preparer.Prepare(apiResponse)
	require.NoError(t, err)

	HandleFileUploads(response, httpRequest, handler, apiResponse, &testFormProcessor{}, opts)
	testhelper.AssertResponseCode(t, response, 422)
}

func newProxy(url string) *proxy.Proxy {
	parsedURL := helper.URLMustParse(url)
	return proxy.NewProxy(parsedURL, "123", roundtripper.NewTestBackendRoundTripper(parsedURL))
}

func waitUntilDeleted(t *testing.T, path string) {
	var err error

	// Poll because the file removal is async
	for i := 0; i < 100; i++ {
		_, err = os.Stat(path)
		if err != nil {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}

	if !os.IsNotExist(err) {
		t.Fatal("expected the file to be deleted")
	}
}
