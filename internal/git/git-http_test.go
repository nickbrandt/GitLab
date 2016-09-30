package git

import (
	"bytes"
	"testing"
)

func TestBbufferUploadPackRequestLimiting(t *testing.T) {
	_, err := bufferUploadPackRequest(bytes.NewReader(make([]byte, 2000000)))
	t.Log(err)

	if err == nil {
		t.Fatalf("expected an error, received nil")
	}
}
