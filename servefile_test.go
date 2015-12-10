package main

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

func TestServingNonExistingFile(t *testing.T) {
	dir := "/path/to/non/existing/directory"
	request := &gitRequest{
		relativeURIPath: "/static/file",
	}

	w := httptest.NewRecorder()
	handleServeFile(&dir, nil)(w, request)
	assertResponseCode(t, w, 404)
}

func TestServingDirectory(t *testing.T) {
	dir, err := ioutil.TempDir("", "deploy")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	request := &gitRequest{
		relativeURIPath: "/",
	}

	w := httptest.NewRecorder()
	handleServeFile(&dir, nil)(w, request)
	assertResponseCode(t, w, 404)
}

func TestServingMalformedUri(t *testing.T) {
	dir := "/path/to/non/existing/directory"
	request := &gitRequest{
		relativeURIPath: "/../../../static/file",
	}

	w := httptest.NewRecorder()
	handleServeFile(&dir, nil)(w, request)
	assertResponseCode(t, w, 500)
}

func TestExecutingHandlerWhenNoFileFound(t *testing.T) {
	dir := "/path/to/non/existing/directory"
	request := &gitRequest{
		relativeURIPath: "/static/file",
	}

	executed := false
	handleServeFile(&dir, func(w http.ResponseWriter, r *gitRequest) {
		executed = (r == request)
	})(nil, request)
	if !executed {
		t.Error("The handler should get executed")
	}
}

func TestServingTheActualFile(t *testing.T) {
	dir, err := ioutil.TempDir("", "deploy")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	httpRequest, _ := http.NewRequest("GET", "/file", nil)
	request := &gitRequest{
		Request:         httpRequest,
		relativeURIPath: "/file",
	}

	fileContent := "STATIC"
	ioutil.WriteFile(filepath.Join(dir, "file"), []byte(fileContent), 0600)

	w := httptest.NewRecorder()
	handleServeFile(&dir, nil)(w, request)
	assertResponseCode(t, w, 200)
	if w.Body.String() != fileContent {
		t.Error("We should serve the file: ", w.Body.String())
	}
}
