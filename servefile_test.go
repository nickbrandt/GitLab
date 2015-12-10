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
		relativeUriPath: "/static/file",
	}

	w := httptest.NewRecorder()
	handleServeFile(&dir, nil)(w, request)
	if w.Code != 404 {
		t.Fatal("Expected to receive 404, since no default handler is provided")
	}
}

func TestServingDirectory(t *testing.T) {
	dir, err := ioutil.TempDir("", "deploy")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	request := &gitRequest{
		relativeUriPath: "/",
	}

	w := httptest.NewRecorder()
	handleServeFile(&dir, nil)(w, request)
	if w.Code != 404 {
		t.Fatal("Expected to receive 404, since we will serve the directory")
	}
}

func TestServingMalformedUri(t *testing.T) {
	dir := "/path/to/non/existing/directory"
	request := &gitRequest{
		relativeUriPath: "/../../../static/file",
	}

	w := httptest.NewRecorder()
	handleServeFile(&dir, nil)(w, request)
	if w.Code != 500 {
		t.Fatal("Expected to receive 500, since client provided invalid URI")
	}
}

func TestExecutingHandlerWhenNoFileFound(t *testing.T) {
	dir := "/path/to/non/existing/directory"
	request := &gitRequest{
		relativeUriPath: "/static/file",
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
		relativeUriPath: "/file",
	}

	fileContent := "DEPLOY"
	ioutil.WriteFile(filepath.Join(dir, "file"), []byte(fileContent), 0600)

	w := httptest.NewRecorder()
	handleServeFile(&dir, nil)(w, request)
	if w.Code != 200 {
		t.Fatal("Expected to receive 200, since we serve existing file")
	}
	if w.Body.String() != fileContent {
		t.Error("We should serve the file: ", w.Body.String())
	}
}
