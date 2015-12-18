package main

import (
	"./internal/helper"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

func TestIfNoDeployPageExist(t *testing.T) {
	dir, err := ioutil.TempDir("", "deploy")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	w := httptest.NewRecorder()

	executed := false
	handleDeployPage(&dir, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		executed = true
	}))(w, nil)
	if !executed {
		t.Error("The handler should get executed")
	}
}

func TestIfDeployPageExist(t *testing.T) {
	dir, err := ioutil.TempDir("", "deploy")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	deployPage := "DEPLOY"
	ioutil.WriteFile(filepath.Join(dir, "index.html"), []byte(deployPage), 0600)

	w := httptest.NewRecorder()

	executed := false
	handleDeployPage(&dir, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		executed = true
	}))(w, nil)
	if executed {
		t.Error("The handler should not get executed")
	}
	w.Flush()

	helper.AssertResponseCode(t, w, 200)
	helper.AssertResponseBody(t, w, deployPage)
}
