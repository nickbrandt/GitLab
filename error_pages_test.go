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

	assertResponseCode(t, w, 404)
	assertResponseBody(t, w, errorPage)
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

	assertResponseCode(t, w, 404)
	assertResponseBody(t, w, errorResponse)
}
