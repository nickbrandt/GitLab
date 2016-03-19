package artifacts

import (
	"archive/zip"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

func testArtifactDownloadServer(t *testing.T, archive string, entry string) *httptest.Server {
	mux := http.NewServeMux()
	mux.HandleFunc("/url/path", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "GET" {
			t.Fatal("Expected GET request")
		}

		w.Header().Set("Content-Type", "application/json")

		data, err := json.Marshal(&api.Response{
			Archive: archive,
			Entry:   base64.StdEncoding.EncodeToString([]byte(entry)),
		})
		if err != nil {
			t.Fatal(err)
		}
		w.Write(data)
	})
	return testhelper.TestServerWithHandler(nil, mux.ServeHTTP)
}

func testDownloadArtifact(t *testing.T, ts *httptest.Server) *httptest.ResponseRecorder {
	httpRequest, err := http.NewRequest("GET", ts.URL+"/url/path", nil)
	if err != nil {
		t.Fatal(err)
	}
	response := httptest.NewRecorder()
	apiClient := api.NewAPI(helper.URLMustParse(ts.URL), "123", nil)
	DownloadArtifact(apiClient).ServeHTTP(response, httpRequest)
	return response
}

func TestDownloadingFromValidArchive(t *testing.T) {
	tempFile, err := ioutil.TempFile("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer tempFile.Close()
	defer os.Remove(tempFile.Name())

	archive := zip.NewWriter(tempFile)
	defer archive.Close()
	fileInArchive, err := archive.Create("test.txt")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Fprint(fileInArchive, "testtest")
	archive.Close()

	ts := testArtifactDownloadServer(t, tempFile.Name(), "test.txt")
	defer ts.Close()

	response := testDownloadArtifact(t, ts)
	testhelper.AssertResponseCode(t, response, 200)

	testhelper.AssertResponseHeader(t, response,
		"Content-Type",
		"text/plain; charset=utf-8")
	testhelper.AssertResponseHeader(t, response,
		"Content-Disposition",
		"attachment; filename=\"test.txt\"")

	testhelper.AssertResponseBody(t, response, "testtest")
}

func TestDownloadingNonExistingFile(t *testing.T) {
	tempFile, err := ioutil.TempFile("", "uploads")
	if err != nil {
		t.Fatal(err)
	}
	defer tempFile.Close()
	defer os.Remove(tempFile.Name())

	archive := zip.NewWriter(tempFile)
	defer archive.Close()
	archive.Close()

	ts := testArtifactDownloadServer(t, tempFile.Name(), "test")
	defer ts.Close()

	response := testDownloadArtifact(t, ts)
	testhelper.AssertResponseCode(t, response, 404)
}

func TestDownloadingFromInvalidArchive(t *testing.T) {
	ts := testArtifactDownloadServer(t, "path/to/non/existing/file", "test")
	defer ts.Close()

	response := testDownloadArtifact(t, ts)
	testhelper.AssertResponseCode(t, response, 404)
}

func TestIncompleteApiResponse(t *testing.T) {
	ts := testArtifactDownloadServer(t, "", "")
	defer ts.Close()

	response := testDownloadArtifact(t, ts)
	testhelper.AssertResponseCode(t, response, 500)
}
