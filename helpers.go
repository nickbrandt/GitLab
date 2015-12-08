/*
Miscellaneous helpers: logging, errors, subprocesses
*/

package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"strings"
	"syscall"
)

func fail400(w http.ResponseWriter, err error) {
	http.Error(w, "Bad request", 400)
	logError(err)
}

func fail500(w http.ResponseWriter, err error) {
	http.Error(w, "Internal server error", 500)
	logError(err)
}

func logError(err error) {
	log.Printf("error: %v", err)
}

// Git subprocess helpers
func gitCommand(gl_id string, name string, args ...string) *exec.Cmd {
	cmd := exec.Command(name, args...)
	// Start the command in its own process group (nice for signalling)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	// Explicitly set the environment for the Git command
	cmd.Env = []string{
		fmt.Sprintf("HOME=%s", os.Getenv("HOME")),
		fmt.Sprintf("PATH=%s", os.Getenv("PATH")),
		fmt.Sprintf("LD_LIBRARY_PATH=%s", os.Getenv("LD_LIBRARY_PATH")),
		fmt.Sprintf("GL_ID=%s", gl_id),
	}
	// If we don't do something with cmd.Stderr, Git errors will be lost
	cmd.Stderr = os.Stderr
	return cmd
}

func cleanUpProcessGroup(cmd *exec.Cmd) {
	if cmd == nil {
		return
	}

	process := cmd.Process
	if process != nil && process.Pid > 0 {
		// Send SIGTERM to the process group of cmd
		syscall.Kill(-process.Pid, syscall.SIGTERM)
	}

	// reap our child process
	cmd.Wait()
}

func forwardResponseToClient(w http.ResponseWriter, r *http.Response) {
	log.Printf("PROXY:%s %q %d", r.Request.Method, r.Request.URL, r.StatusCode)

	for k, v := range r.Header {
		w.Header()[k] = v
	}

	w.WriteHeader(r.StatusCode)
	io.Copy(w, r.Body)
}

func setHttpPostForm(r *http.Request, values url.Values) {
	dataBuffer := strings.NewReader(values.Encode())
	r.Body = ioutil.NopCloser(dataBuffer)
	r.ContentLength = int64(dataBuffer.Len())
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
}
