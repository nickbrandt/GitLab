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
const testProject = "test"

var remote = fmt.Sprintf("http://%s/%s", servAddr, testRepo)
var checkoutDir = path.Join(scratchDir, "test")

func TestAllowedClone(t *testing.T) {
	// Prepare clone directory
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}

	// Prepare test server and backend
	ts := testAuthServer(200, `{"GL_ID":"user-123"}`)
	defer ts.Close()
	defer cleanUpProcessGroup(startServerOrFail(t, ts))

	// Do the git clone
	cloneCmd := exec.Command("git", "clone", remote, checkoutDir)
	runOrFail(t, cloneCmd)

	// We may have cloned an 'empty' repository, 'git log' will fail in it
	logCmd := exec.Command("git", "log", "-1", "--oneline")
	logCmd.Dir = checkoutDir
	runOrFail(t, logCmd)
}

func TestDeniedClone(t *testing.T) {
	// Prepare clone directory
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}

	// Prepare test server and backend
	ts := testAuthServer(403, "Access denied")
	defer ts.Close()
	defer cleanUpProcessGroup(startServerOrFail(t, ts))

	// Do the git clone
	cloneCmd := exec.Command("git", "clone", remote, checkoutDir)
	out, err := cloneCmd.CombinedOutput()
	t.Logf("%s", out)
	if err == nil {
		t.Fatal("git clone should have failed")
	}
}

func TestAllowedPush(t *testing.T) {
	preparePushRepo(t)

	// Prepare the test server and backend
	ts := testAuthServer(200, `{"GL_ID":"user-123"}`)
	defer ts.Close()
	defer cleanUpProcessGroup(startServerOrFail(t, ts))

	// Perform the git push
	pushCmd := exec.Command("git", "push", remote, fmt.Sprintf("master:%s", newBranch()))
	pushCmd.Dir = checkoutDir
	runOrFail(t, pushCmd)
}

func TestDeniedPush(t *testing.T) {
	preparePushRepo(t)

	// Prepare the test server and backend
	ts := testAuthServer(403, "Access denied")
	defer ts.Close()
	defer cleanUpProcessGroup(startServerOrFail(t, ts))

	// Perform the git push
	pushCmd := exec.Command("git", "push", "-v", remote, fmt.Sprintf("master:%s", newBranch()))
	pushCmd.Dir = checkoutDir
	out, err := pushCmd.CombinedOutput()
	t.Logf("%s", out)
	if err == nil {
		t.Fatal("git push should have failed")
	}
}

func TestAllowedDownloadZip(t *testing.T) {
	prepareDownloadDir(t)

	// Prepare test server and backend
	archiveName := "foobar.zip"
	ts := testAuthServer(200, fmt.Sprintf(`{"ArchivePath":"/tmp/%s"}`, archiveName))
	defer ts.Close()
	defer cleanUpProcessGroup(startServerOrFail(t, ts))

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("http://%s/%s/repository/archive.zip", servAddr, testProject))
	downloadCmd.Dir = scratchDir
	runOrFail(t, downloadCmd)

	extractCmd := exec.Command("unzip", archiveName)
	extractCmd.Dir = scratchDir
	runOrFail(t, extractCmd)
}

func TestAllowedDownloadTar(t *testing.T) {
	prepareDownloadDir(t)

	// Prepare test server and backend
	archiveName := "foobar.tar"
	ts := testAuthServer(200, fmt.Sprintf(`{"ArchivePath":"/tmp/%s"}`, archiveName))
	defer ts.Close()
	defer cleanUpProcessGroup(startServerOrFail(t, ts))

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("http://%s/%s/repository/archive.tar", servAddr, testProject))
	downloadCmd.Dir = scratchDir
	runOrFail(t, downloadCmd)

	extractCmd := exec.Command("tar", "xf", archiveName)
	extractCmd.Dir = scratchDir
	runOrFail(t, extractCmd)
}

func TestAllowedDownloadTarGz(t *testing.T) {
	prepareDownloadDir(t)

	// Prepare test server and backend
	archiveName := "foobar.tar.gz"
	ts := testAuthServer(200, fmt.Sprintf(`{"ArchivePath":"/tmp/%s"}`, archiveName))
	defer ts.Close()
	defer cleanUpProcessGroup(startServerOrFail(t, ts))

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("http://%s/%s/repository/archive.tar.gz", servAddr, testProject))
	downloadCmd.Dir = scratchDir
	runOrFail(t, downloadCmd)

	extractCmd := exec.Command("tar", "zxf", archiveName)
	extractCmd.Dir = scratchDir
	runOrFail(t, extractCmd)
}

func TestAllowedDownloadTarBz2(t *testing.T) {
	prepareDownloadDir(t)

	// Prepare test server and backend
	archiveName := "foobar.tar.bz2"
	ts := testAuthServer(200, fmt.Sprintf(`{"ArchivePath":"/tmp/%s"}`, archiveName))
	defer ts.Close()
	defer cleanUpProcessGroup(startServerOrFail(t, ts))

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("http://%s/%s/repository/archive.tar.bz2", servAddr, testProject))
	downloadCmd.Dir = scratchDir
	runOrFail(t, downloadCmd)

	extractCmd := exec.Command("tar", "jxf", archiveName)
	extractCmd.Dir = scratchDir
	runOrFail(t, extractCmd)
}

func prepareDownloadDir(t *testing.T) {
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(scratchDir, 0755); err != nil {
		t.Fatal(err)
	}
}

func preparePushRepo(t *testing.T) {
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}
	cloneCmd := exec.Command("git", "clone", path.Join(testRepoRoot, testRepo), checkoutDir)
	runOrFail(t, cloneCmd)
	return
}

func newBranch() string {
	return fmt.Sprintf("branch-%d", time.Now().UnixNano())
}

func testAuthServer(code int, body string) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(code)
		fmt.Fprint(w, body)
	}))
}

func startServerOrFail(t *testing.T, ts *httptest.Server) *exec.Cmd {
	cmd := exec.Command("go", "run", "main.go", "githandler.go", fmt.Sprintf("-authBackend=%s", ts.URL), fmt.Sprintf("-listenAddr=%s", servAddr), testRepoRoot)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}

	if err := waitServer(); err != nil {
		cleanUpProcessGroup(cmd)
		t.Fatal(err)
	}

	return cmd
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
	out, err := cmd.CombinedOutput()
	t.Logf("%s", out)
	if err != nil {
		t.Fatal(err)
	}
}
