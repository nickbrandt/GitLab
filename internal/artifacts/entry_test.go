package artifacts

import (
	"archive/zip"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
)

func testEntryServer(t *testing.T, archive string, entry string) *httptest.ResponseRecorder {
	mux := http.NewServeMux()
	mux.HandleFunc("/url/path", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "GET" {
			t.Fatal("Expected GET request")
		}

		encodedEntry := base64.StdEncoding.EncodeToString([]byte(entry))
		jsonParams := fmt.Sprintf(`{"Archive":"%s","Entry":"%s"}`, archive, encodedEntry)
		data := base64.URLEncoding.EncodeToString([]byte(jsonParams))

		SendEntry.Inject(w, r, data)
	})

	httpRequest, err := http.NewRequest("GET", "/url/path", nil)
	if err != nil {
		t.Fatal(err)
	}
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, httpRequest)
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

	response := testEntryServer(t, tempFile.Name(), "test.txt")

	testhelper.AssertResponseCode(t, response, 200)

	testhelper.AssertResponseWriterHeader(t, response,
		"Content-Type",
		"text/plain; charset=utf-8")
	testhelper.AssertResponseWriterHeader(t, response,
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

	response := testEntryServer(t, tempFile.Name(), "test")
	testhelper.AssertResponseCode(t, response, 404)
}

func TestDownloadingFromInvalidArchive(t *testing.T) {
	response := testEntryServer(t, "path/to/non/existing/file", "test")
	testhelper.AssertResponseCode(t, response, 404)
}

func TestIncompleteApiResponse(t *testing.T) {
	response := testEntryServer(t, "", "")
	testhelper.AssertResponseCode(t, response, 500)
}
