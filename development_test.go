package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestDevelopmentModeEnabled(t *testing.T) {
	developmentMode := true

	r, _ := http.NewRequest("GET", "/something", nil)
	w := httptest.NewRecorder()

	executed := false
	handleDevelopmentMode(&developmentMode, func(w http.ResponseWriter, r *gitRequest) {
		executed = true
	})(w, &gitRequest{Request: r})
	if !executed {
		t.Error("The handler should get executed")
	}
}

func TestDevelopmentModeDisabled(t *testing.T) {
	developmentMode := false

	r, _ := http.NewRequest("GET", "/something", nil)
	w := httptest.NewRecorder()

	executed := false
	handleDevelopmentMode(&developmentMode, func(w http.ResponseWriter, r *gitRequest) {
		executed = true
	})(w, &gitRequest{Request: r})
	if executed {
		t.Error("The handler should not get executed")
	}
	assertResponseCode(t, w, 404)
}
