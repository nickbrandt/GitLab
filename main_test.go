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

func TestAllowedClone(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, `{"GL_ID":"user-123"}`)
	}))
	defer ts.Close()
	defer cleanUpProcessGroup(startServer(t, ts))
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}
	cloneCmd := exec.Command("git", "clone", fmt.Sprintf("http://%s/test.git", servAddr), path.Join(scratchDir, "test"))
	if out, err := cloneCmd.CombinedOutput(); err != nil {
		t.Logf("%s", out)
		t.Fatal(err)
	}
}

func startServer(t *testing.T, ts *httptest.Server) (cmd *exec.Cmd) {
	var conn net.Conn
	var err error
	cmd = exec.Command("go", "run", "main.go", fmt.Sprintf("-authBackend=%s", ts.URL), fmt.Sprintf("-listenAddr=%s", servAddr), testRepoRoot)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	for i := 0; i < servWaitListen/servWaitSleep; i++ {
		conn, err = net.Dial("tcp", servAddr)
		if err == nil {
			conn.Close()
			break
		}
		time.Sleep(servWaitSleep * time.Millisecond)
	}
	if err != nil {
		t.Fatal(err)
	}
	return
}
