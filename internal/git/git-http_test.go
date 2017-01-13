package git

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
)

const (
	expectedBytes = 102400
	GL_ID         = "test-user"
)

// From https://npf.io/2015/06/testing-exec-command/
func fakeExecCommand(command string, args ...string) *exec.Cmd {
	cs := []string{"-test.run=TestGitCommandProcess", "--", command}
	cs = append(cs, args...)
	cmd := exec.Command(os.Args[0], cs...)
	return cmd
}

func createTestPayload() []byte {
	return bytes.Repeat([]byte{'0'}, expectedBytes)
}

func TestRunUploadPack(t *testing.T) {
	execCommand = fakeExecCommand
	defer func() { execCommand = exec.Command }()

	testInput := createTestPayload()
	body := bytes.NewReader([]byte(testInput))
	req, err := http.NewRequest("GET", "/gitlab/gitlab-ce.git/?service=git-upload-pack", body)

	if err != nil {
		t.Fatal(err)
	}

	resp := &api.Response{GL_ID: GL_ID}

	rr := httptest.NewRecorder()
	handlePostRPC(rr, req, resp)

	// Check HTTP status code
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: expected: %v, got %v",
			http.StatusOK, status)
	}

	headers := []struct {
		key   string
		value string
	}{
		{"Content-Type", "application/x-git-upload-pack-result"},
		{"Cache-Control", "no-cache"},
	}

	// Check HTTP headers
	for _, h := range headers {
		if value := rr.Header().Get(h.key); value != h.value {
			t.Errorf("HTTP header %v does not match: expected: %v, got %v",
				h.key, h.value, value)
		}
	}

	if rr.Body.String() != string(testInput) {
		t.Errorf("handler did not echo back properly: got %d, expected %d bytes",
			len(rr.Body.String()), len(testInput))
	}
}

func TestGitCommandProcess(t *testing.T) {
	if os.Getenv("GL_ID") != GL_ID {
		return
	}

	defer os.Exit(0)

	// Echo back the input to test sender
	io.Copy(os.Stdout, os.Stdin)
}
