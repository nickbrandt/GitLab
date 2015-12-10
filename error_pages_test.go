package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

func TestIfErrorPageIsPresented(t *testing.T) {
	dir, err := ioutil.TempDir("", "error_page")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	errorPage := "ERROR"
	ioutil.WriteFile(filepath.Join(dir, "404.html"), []byte(errorPage), 0600)

	w := httptest.NewRecorder()

	handleRailsError(&dir, func(w http.ResponseWriter, r *gitRequest) {
		w.WriteHeader(404)
		fmt.Fprint(w, "Not Found")
	})(w, nil)
	w.Flush()

	if w.Code != 404 {
		t.Error("Page should be 404")
	}
	if w.Body.String() != errorPage {
		t.Error("Page should be custom error page: ", w.Body.String())
	}
}

func TestIfErrorPassedIfNoErrorPageIsFound(t *testing.T) {
	dir, err := ioutil.TempDir("", "error_page")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	w := httptest.NewRecorder()
	errorResponse := "ERROR"

	handleRailsError(&dir, func(w http.ResponseWriter, r *gitRequest) {
		w.WriteHeader(404)
		fmt.Fprint(w, errorResponse)
	})(w, nil)
	w.Flush()

	if w.Code != 404 {
		t.Error("Page should be 400")
	}
	if w.Body.String() != errorResponse {
		t.Error("Page should be response error: ", w.Body.String())
	}
}
