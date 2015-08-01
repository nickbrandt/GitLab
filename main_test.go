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
	ts := testAuthServer(200, `{"GL_ID":"user-123"}`)
	defer ts.Close()
	cmd, err := startServer(ts)
	if err != nil {
		t.Fatal(err)
	}
	defer cleanUpProcessGroup(cmd)
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}
	cloneCmd := exec.Command("git", "clone", remote, path.Join(scratchDir, "test"))
	if out, err := cloneCmd.CombinedOutput(); err != nil {
		t.Logf("%s", out)
		t.Fatal(err)
	}
}

func TestAllowedPush(t *testing.T) {
	// Prepare the repo to push from
	checkoutDir := path.Join(scratchDir, "test")
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}
	cloneCmd := exec.Command("git", "clone", path.Join(testRepoRoot, testRepo), checkoutDir)
	if out, err := cloneCmd.CombinedOutput(); err != nil {
		t.Logf("%s", out)
		t.Fatal(err)
	}
	branch := fmt.Sprintf("branch-%d", time.Now().UnixNano())
	branchCmd := exec.Command("git", "branch", branch)
	branchCmd.Dir = checkoutDir
	if out, err := branchCmd.CombinedOutput(); err != nil {
		t.Logf("%s", out)
		t.Fatal(err)
	}

	// Prepare the test server and backend
	ts := testAuthServer(200, `{"GL_ID":"user-123"}`)
	defer ts.Close()
	cmd, err := startServer(ts)
	if err != nil {
		t.Fatal(err)
	}
	defer cleanUpProcessGroup(cmd)

	// Perform the git push
	pushCmd := exec.Command("git", "push", remote, branch)
	pushCmd.Dir = checkoutDir
	if out, err := pushCmd.CombinedOutput(); err != nil {
		t.Logf("%s", out)
		t.Fatal(err)
	}
}

func testAuthServer(code int, body string) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(code)
		fmt.Fprint(w, body)
	}))
}

func startServer(ts *httptest.Server) (cmd *exec.Cmd, err error) {
	var conn net.Conn

	// Start our server process
	cmd = exec.Command("go", "run", "main.go", fmt.Sprintf("-authBackend=%s", ts.URL), fmt.Sprintf("-listenAddr=%s", servAddr), testRepoRoot)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	err = cmd.Start()
	if err != nil {
		return
	}

	// Wait for the server to start accepting TCP connections
	for i := 0; i < servWaitListen/servWaitSleep; i++ {
		conn, err = net.Dial("tcp", servAddr)
		if err == nil {
			conn.Close()
			break
		}
		time.Sleep(servWaitSleep * time.Millisecond)
	}
	if err != nil {
		cleanUpProcessGroup(cmd)
	}

	return
}
