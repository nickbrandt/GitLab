package main

import (
	"./internal/helper"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestDevelopmentModeEnabled(t *testing.T) {
	developmentMode := true

	r, _ := http.NewRequest("GET", "/something", nil)
	w := httptest.NewRecorder()

	executed := false
	handleDevelopmentMode(&developmentMode, func(_ http.ResponseWriter, _ *http.Request) {
		executed = true
	})(w, r)
	if !executed {
		t.Error("The handler should get executed")
	}
}

func TestDevelopmentModeDisabled(t *testing.T) {
	developmentMode := false

	r, _ := http.NewRequest("GET", "/something", nil)
	w := httptest.NewRecorder()

	executed := false
	handleDevelopmentMode(&developmentMode, func(_ http.ResponseWriter, _ *http.Request) {
		executed = true
	})(w, r)
	if executed {
		t.Error("The handler should not get executed")
	}
	helper.AssertResponseCode(t, w, 404)
}
