package main

import (
	"fmt"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path"
	"syscall"
	"testing"
	"time"
)

const servAddr = "127.0.0.1:8181"
const servWaitListen = 10000 // milliseconds to wait for server to start listening
const servWaitSleep = 100    // milliseconds sleep interval
const scratchDir = "test/scratch"
const testRepoRoot = "test/data"
const testRepo = "test.git"

var remote = fmt.Sprintf("http://%s/%s", servAddr, testRepo)

func TestAllowedClone(t *testing.T) {
	// Prepare clone directory
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}

	// Prepare test server and backend
	ts := testAuthServer(200, `{"GL_ID":"user-123"}`)
	defer ts.Close()
	cmd, err := startServer(ts)
	if err != nil {
		t.Fatal(err)
	}
	defer cleanUpProcessGroup(cmd)
	if err := waitServer(); err != nil {
		t.Fatal(err)
	}

	// Do the git clone
	cloneCmd := exec.Command("git", "clone", remote, path.Join(scratchDir, "test"))
	runOrFail(t, cloneCmd)

	// We may have cloned an 'empty' repository, 'git show' will fail in it
	showCmd := exec.Command("git", "show")
	showCmd.Dir = path.Join(scratchDir, "test")
	runOrFail(t, showCmd)
}

func TestDeniedClone(t *testing.T) {
	// Prepare clone directory
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}

	// Prepare test server and backend
	ts := testAuthServer(403, "Denied")
	defer ts.Close()
	cmd, err := startServer(ts)
	if err != nil {
		t.Fatal(err)
	}
	defer cleanUpProcessGroup(cmd)
	if err := waitServer(); err != nil {
		t.Fatal(err)
	}

	// Do the git clone
	cloneCmd := exec.Command("git", "clone", remote, path.Join(scratchDir, "test"))
	if err := cloneCmd.Run(); err == nil {
		t.Fatal("git clone should have failed")
	}
}

func TestAllowedPush(t *testing.T) {
	// Prepare the repo to push from
	checkoutDir := path.Join(scratchDir, "test")
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}
	cloneCmd := exec.Command("git", "clone", path.Join(testRepoRoot, testRepo), checkoutDir)
	runOrFail(t, cloneCmd)
	branch := fmt.Sprintf("branch-%d", time.Now().UnixNano())
	branchCmd := exec.Command("git", "branch", branch)
	branchCmd.Dir = checkoutDir
	runOrFail(t, branchCmd)

	// Prepare the test server and backend
	ts := testAuthServer(200, `{"GL_ID":"user-123"}`)
	defer ts.Close()
	cmd, err := startServer(ts)
	if err != nil {
		t.Fatal(err)
	}
	defer cleanUpProcessGroup(cmd)
	if err := waitServer(); err != nil {
		t.Fatal(err)
	}

	// Perform the git push
	pushCmd := exec.Command("git", "push", remote, branch)
	pushCmd.Dir = checkoutDir
	runOrFail(t, pushCmd)
}

func testAuthServer(code int, body string) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(code)
		fmt.Fprint(w, body)
	}))
}

func startServer(ts *httptest.Server) (*exec.Cmd, error) {
	cmd := exec.Command("go", "run", "main.go", fmt.Sprintf("-authBackend=%s", ts.URL), fmt.Sprintf("-listenAddr=%s", servAddr), testRepoRoot)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	return cmd, cmd.Start()
}

func waitServer() (err error) {
	var conn net.Conn

	for i := 0; i < servWaitListen/servWaitSleep; i++ {
		conn, err = net.Dial("tcp", servAddr)
		if err == nil {
			conn.Close()
			return
		}
		time.Sleep(servWaitSleep * time.Millisecond)
	}
	return
}

func runOrFail(t *testing.T, cmd *exec.Cmd) {
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Logf("%s", out)
		t.Fatal(err)
	}
}
