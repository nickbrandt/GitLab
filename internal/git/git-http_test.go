package git

import (
	"bytes"
	"testing"
)

func TestBufferPostBodyLimiting(t *testing.T) {
	_, err := bufferPostBody(bytes.NewReader(make([]byte, 2000000)))
	t.Log(err)

	if err == nil {
		t.Fatalf("expected an error, received nil")
	}

}
