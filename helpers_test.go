package main

import (
	"net/http/httptest"
	"testing"
)

func assertResponseCode(t *testing.T, response *httptest.ResponseRecorder, expectedCode int) {
	if response.Code != expectedCode {
		t.Fatalf("for HTTP request expected to get %d, got %d instead", expectedCode, response.Code)
	}
}

func assertResponseBody(t *testing.T, response *httptest.ResponseRecorder, expectedBody string) {
	if response.Body.String() != expectedBody {
		t.Fatalf("for HTTP request expected to receive %q, got %q instead as body", expectedBody, response.Body.String())
	}
}
