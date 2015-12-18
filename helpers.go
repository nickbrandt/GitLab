/*
Miscellaneous helpers: logging, errors, subprocesses
*/

package main

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path"
	"syscall"
)

func httpError(w http.ResponseWriter, r *http.Request, error string, code int) {
	if r.ProtoAtLeast(1, 1) {
		// Force client to disconnect if we render request error
		w.Header().Set("Connection", "close")
	}

	http.Error(w, error, code)
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

// Borrowed from: net/http/server.go
// Return the canonical path for p, eliminating . and .. elements.
func cleanURIPath(p string) string {
	if p == "" {
		return "/"
	}
	if p[0] != '/' {
		p = "/" + p
	}
	np := path.Clean(p)
	// path.Clean removes trailing slash except for root;
	// put the trailing slash back if necessary.
	if p[len(p)-1] == '/' && np != "/" {
		np += "/"
	}
	return np
}
