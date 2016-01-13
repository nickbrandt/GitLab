package main

import (
	"./internal/api"
	"./internal/helper"
	"./internal/upstream"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path"
	"regexp"
	"strings"
	"testing"
	"time"
)

const scratchDir = "testdata/scratch"
const testRepoRoot = "testdata/data"
const testDocumentRoot = "testdata/public"
const testRepo = "group/test.git"
const testProject = "group/test"

var checkoutDir = path.Join(scratchDir, "test")
var cacheDir = path.Join(scratchDir, "cache")

func TestAllowedClone(t *testing.T) {
	// Prepare clone directory
	if err := os.RemoveAll(scratchDir); err != nil {
		t.Fatal(err)
	}

	// Prepare test server and backend
	ts := testAuthServer(nil, 200, gitOkBody(t))
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Do the git clone
	cloneCmd := exec.Command("git", "clone", fmt.Sprintf("%s/%s", ws.URL, testRepo), checkoutDir)
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
	ts := testAuthServer(nil, 403, "Access denied")
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Do the git clone
	cloneCmd := exec.Command("git", "clone", fmt.Sprintf("%s/%s", ws.URL, testRepo), checkoutDir)
	out, err := cloneCmd.CombinedOutput()
	t.Logf("%s", out)
	if err == nil {
		t.Fatal("git clone should have failed")
	}
}

func TestAllowedPush(t *testing.T) {
	preparePushRepo(t)

	// Prepare the test server and backend
	ts := testAuthServer(nil, 200, gitOkBody(t))
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Perform the git push
	pushCmd := exec.Command("git", "push", fmt.Sprintf("%s/%s", ws.URL, testRepo), fmt.Sprintf("master:%s", newBranch()))
	pushCmd.Dir = checkoutDir
	runOrFail(t, pushCmd)
}

func TestDeniedPush(t *testing.T) {
	preparePushRepo(t)

	// Prepare the test server and backend
	ts := testAuthServer(nil, 403, "Access denied")
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Perform the git push
	pushCmd := exec.Command("git", "push", "-v", fmt.Sprintf("%s/%s", ws.URL, testRepo), fmt.Sprintf("master:%s", newBranch()))
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
	ts := testAuthServer(nil, 200, archiveOkBody(t, archiveName))
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("%s/%s/repository/archive.zip", ws.URL, testProject))
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
	ts := testAuthServer(nil, 200, archiveOkBody(t, archiveName))
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("%s/%s/repository/archive.tar", ws.URL, testProject))
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
	ts := testAuthServer(nil, 200, archiveOkBody(t, archiveName))
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("%s/%s/repository/archive.tar.gz", ws.URL, testProject))
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
	ts := testAuthServer(nil, 200, archiveOkBody(t, archiveName))
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("%s/%s/repository/archive.tar.bz2", ws.URL, testProject))
	downloadCmd.Dir = scratchDir
	runOrFail(t, downloadCmd)

	extractCmd := exec.Command("tar", "jxf", archiveName)
	extractCmd.Dir = scratchDir
	runOrFail(t, extractCmd)
}

func TestAllowedApiDownloadZip(t *testing.T) {
	prepareDownloadDir(t)

	// Prepare test server and backend
	archiveName := "foobar.zip"
	ts := testAuthServer(nil, 200, archiveOkBody(t, archiveName))
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("%s/api/v3/projects/123/repository/archive.zip", ws.URL))
	downloadCmd.Dir = scratchDir
	runOrFail(t, downloadCmd)

	extractCmd := exec.Command("unzip", archiveName)
	extractCmd.Dir = scratchDir
	runOrFail(t, extractCmd)
}

func TestAllowedApiDownloadZipWithSlash(t *testing.T) {
	prepareDownloadDir(t)

	// Prepare test server and backend
	archiveName := "foobar.zip"
	ts := testAuthServer(nil, 200, archiveOkBody(t, archiveName))
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Use foo%2Fbar instead of a numeric ID
	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("%s/api/v3/projects/foo%%2Fbar/repository/archive.zip", ws.URL))
	if !strings.Contains(downloadCmd.Args[3], `projects/foo%2Fbar/repository`) {
		t.Fatalf("Cannot find percent-2F: %v", downloadCmd.Args)
	}
	downloadCmd.Dir = scratchDir
	runOrFail(t, downloadCmd)

	extractCmd := exec.Command("unzip", archiveName)
	extractCmd.Dir = scratchDir
	runOrFail(t, extractCmd)
}

func TestDownloadCacheHit(t *testing.T) {
	prepareDownloadDir(t)

	// Prepare test server and backend
	archiveName := "foobar.zip"
	ts := testAuthServer(nil, 200, archiveOkBody(t, archiveName))
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	if err := os.MkdirAll(cacheDir, 0755); err != nil {
		t.Fatal(err)
	}
	cachedContent := []byte("cached")
	if err := ioutil.WriteFile(path.Join(cacheDir, archiveName), cachedContent, 0644); err != nil {
		t.Fatal(err)
	}

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("%s/api/v3/projects/123/repository/archive.zip", ws.URL))
	downloadCmd.Dir = scratchDir
	runOrFail(t, downloadCmd)

	actual, err := ioutil.ReadFile(path.Join(scratchDir, archiveName))
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Compare(actual, cachedContent) != 0 {
		t.Fatal("Unexpected file contents in download")
	}
}

func TestDownloadCacheCreate(t *testing.T) {
	prepareDownloadDir(t)

	// Prepare test server and backend
	archiveName := "foobar.zip"
	ts := testAuthServer(nil, 200, archiveOkBody(t, archiveName))
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	downloadCmd := exec.Command("curl", "-J", "-O", fmt.Sprintf("%s/api/v3/projects/123/repository/archive.zip", ws.URL))
	downloadCmd.Dir = scratchDir
	runOrFail(t, downloadCmd)

	compareCmd := exec.Command("cmp", path.Join(cacheDir, archiveName), path.Join(scratchDir, archiveName))
	if err := compareCmd.Run(); err != nil {
		t.Fatalf("Comparison between downloaded file and cache item failed: %s", err)
	}
}

func TestRegularProjectsAPI(t *testing.T) {
	apiResponse := "API RESPONSE"
	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	for _, resource := range []string{
		"/api/v3/projects/123/repository/not/special",
		"/api/v3/projects/foo%2Fbar/repository/not/special",
		"/api/v3/projects/123/not/special",
		"/api/v3/projects/foo%2Fbar/not/special",
	} {
		resp, err := http.Get(ws.URL + resource)
		if err != nil {
			t.Fatal(err)
		}
		defer resp.Body.Close()
		buf := &bytes.Buffer{}
		if _, err := io.Copy(buf, resp.Body); err != nil {
			t.Error(err)
		}
		if buf.String() != apiResponse {
			t.Errorf("GET %q: Expected %q, got %q", resource, apiResponse, buf.String())
		}
		if resp.StatusCode != 200 {
			t.Errorf("GET %q: expected 200, got %d", resource, resp.StatusCode)
		}
	}
}

func TestAllowedXSendfileDownload(t *testing.T) {
	contentFilename := "my-content"
	prepareDownloadDir(t)

	allowedXSendfileDownload(t, contentFilename, "foo/uploads/bar")
}

func TestDeniedXSendfileDownload(t *testing.T) {
	contentFilename := "my-content"
	prepareDownloadDir(t)

	deniedXSendfileDownload(t, contentFilename, "foo/uploads/bar")
}

func TestAllowedStaticFile(t *testing.T) {
	content := "PUBLIC"
	if err := setupStaticFile("static file.txt", content); err != nil {
		t.Fatalf("create public/static file.txt: %v", err)
	}

	proxied := false
	ts := helper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		proxied = true
		w.WriteHeader(404)
	})
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	for _, resource := range []string{
		"/static%20file.txt",
		"/static file.txt",
	} {
		resp, err := http.Get(ws.URL + resource)
		if err != nil {
			t.Error(err)
		}
		defer resp.Body.Close()
		buf := &bytes.Buffer{}
		if _, err := io.Copy(buf, resp.Body); err != nil {
			t.Error(err)
		}
		if buf.String() != content {
			t.Errorf("GET %q: Expected %q, got %q", resource, content, buf.String())
		}
		if resp.StatusCode != 200 {
			t.Errorf("GET %q: expected 200, got %d", resource, resp.StatusCode)
		}
		if proxied {
			t.Errorf("GET %q: should not have made it to backend", resource)
		}
	}
}

func TestAllowedPublicUploadsFile(t *testing.T) {
	content := "PRIVATE but allowed"
	if err := setupStaticFile("uploads/static file.txt", content); err != nil {
		t.Fatalf("create public/uploads/static file.txt: %v", err)
	}

	proxied := false
	ts := helper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, r *http.Request) {
		proxied = true
		w.Header().Add("X-Sendfile", *documentRoot+r.URL.Path)
		w.WriteHeader(200)
	})
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	for _, resource := range []string{
		"/uploads/static%20file.txt",
		"/uploads/static file.txt",
	} {
		resp, err := http.Get(ws.URL + resource)
		if err != nil {
			t.Fatal(err)
		}
		defer resp.Body.Close()
		buf := &bytes.Buffer{}
		if _, err := io.Copy(buf, resp.Body); err != nil {
			t.Fatal(err)
		}
		if buf.String() != content {
			t.Fatalf("GET %q: Expected %q, got %q", resource, content, buf.String())
		}
		if resp.StatusCode != 200 {
			t.Fatalf("GET %q: expected 200, got %d", resource, resp.StatusCode)
		}
		if !proxied {
			t.Fatalf("GET %q: never made it to backend", resource)
		}
	}
}

func TestDeniedPublicUploadsFile(t *testing.T) {
	content := "PRIVATE"
	if err := setupStaticFile("uploads/static.txt", content); err != nil {
		t.Fatalf("create public/uploads/static.txt: %v", err)
	}

	proxied := false
	ts := helper.TestServerWithHandler(regexp.MustCompile(`.`), func(w http.ResponseWriter, _ *http.Request) {
		proxied = true
		w.WriteHeader(404)
	})
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	for _, resource := range []string{
		"/uploads/static.txt",
		"/uploads%2Fstatic.txt",
	} {
		resp, err := http.Get(ws.URL + resource)
		if err != nil {
			t.Fatal(err)
		}
		defer resp.Body.Close()
		buf := &bytes.Buffer{}
		if _, err := io.Copy(buf, resp.Body); err != nil {
			t.Fatal(err)
		}
		if buf.String() == content {
			t.Fatalf("GET %q: Got private file contents which should have been blocked by upstream", resource)
		}
		if resp.StatusCode != 404 {
			t.Fatalf("GET %q: expected 404, got %d", resource, resp.StatusCode)
		}
		if !proxied {
			t.Fatalf("GET %q: never made it to backend", resource)
		}
	}
}

func setupStaticFile(fpath, content string) error {
	cwd, err := os.Getwd()
	if err != nil {
		return err
	}
	*documentRoot = path.Join(cwd, testDocumentRoot)
	if err := os.MkdirAll(path.Join(*documentRoot, path.Dir(fpath)), 0755); err != nil {
		return err
	}
	static_file := path.Join(*documentRoot, fpath)
	if err := ioutil.WriteFile(static_file, []byte(content), 0666); err != nil {
		return err
	}
	return nil
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
}

func newBranch() string {
	return fmt.Sprintf("branch-%d", time.Now().UnixNano())
}

func testAuthServer(url *regexp.Regexp, code int, body interface{}) *httptest.Server {
	return helper.TestServerWithHandler(url, func(w http.ResponseWriter, r *http.Request) {
		// Write pure string
		if data, ok := body.(string); ok {
			log.Println("UPSTREAM", r.Method, r.URL, code)
			w.WriteHeader(code)
			fmt.Fprint(w, data)
			return
		}

		// Write json string
		data, err := json.Marshal(body)
		if err != nil {
			log.Println("UPSTREAM", r.Method, r.URL, "FAILURE", err)
			w.WriteHeader(503)
			fmt.Fprint(w, err)
			return
		}

		log.Println("UPSTREAM", r.Method, r.URL, code)
		w.WriteHeader(code)
		w.Write(data)
	})
}

func startWorkhorseServer(authBackend string) *httptest.Server {
	u := &upstream.Upstream{
		Backend:      helper.URLMustParse(authBackend),
		Version:      "123",
		DocumentRoot: testDocumentRoot,
	}
	return httptest.NewServer(u)
}

func runOrFail(t *testing.T, cmd *exec.Cmd) {
	out, err := cmd.CombinedOutput()
	t.Logf("%s", out)
	if err != nil {
		t.Fatal(err)
	}
}

func gitOkBody(t *testing.T) interface{} {
	return &api.Response{
		GL_ID:    "user-123",
		RepoPath: repoPath(t),
	}
}

func archiveOkBody(t *testing.T, archiveName string) interface{} {
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	archivePath := path.Join(cwd, cacheDir, archiveName)

	return &api.Response{
		RepoPath:      repoPath(t),
		ArchivePath:   archivePath,
		CommitId:      "c7fbe50c7c7419d9701eebe64b1fdacc3df5b9dd",
		ArchivePrefix: "foobar123",
	}
}

func repoPath(t *testing.T) string {
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	return path.Join(cwd, testRepoRoot, testRepo)
}
