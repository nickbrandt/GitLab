package main

import (
	"bytes"
	"fmt"
	"math/rand"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path"
	"strconv"
	"strings"
	"testing"
	"time"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"

	pb "gitlab.com/gitlab-org/gitaly-proto/go"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
)

func TestFailedCloneNoGitaly(t *testing.T) {
	// Prepare clone directory
	require.NoError(t, os.RemoveAll(scratchDir))

	authBody := &api.Response{
		GL_ID:    "user-123",
		RepoPath: repoPath(t),
		// This will create a failure to connect to Gitaly
		GitalyServer: gitaly.Server{Address: "unix:/nonexistent"},
	}

	// Prepare test server and backend
	ts := testAuthServer(nil, 200, authBody)
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Do the git clone
	cloneCmd := exec.Command("git", "clone", fmt.Sprintf("%s/%s", ws.URL, testRepo), checkoutDir)
	out, err := cloneCmd.CombinedOutput()
	t.Log(string(out))
	assert.Error(t, err, "git clone should have failed")
}

func TestGetInfoRefsProxiedToGitalySuccessfully(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	gitalyAddress := "unix://" + socketPath

	apiResponse := gitOkBody(t)
	apiResponse.GitalyServer.Address = gitalyAddress

	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/info/refs?service=git-upload-pack"
	_, body := httpGet(t, ws.URL+resource)

	expectedContent := string(testhelper.GitalyInfoRefsResponseMock)
	assert.Equal(t, expectedContent, body, "GET %q: response body", resource)
}

func TestGetInfoRefsProxiedToGitalyInterruptedStream(t *testing.T) {
	apiResponse := gitOkBody(t)
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	gitalyAddress := "unix://" + socketPath
	apiResponse.GitalyServer.Address = gitalyAddress

	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/info/refs?service=git-upload-pack"
	resp, err := http.Get(ws.URL + resource)
	require.NoError(t, err)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	select {
	case <-done:
		return
	case <-time.After(10 * time.Second):
		t.Fatal("time out waiting for gitaly handler to return")
	}
}

func TestPostReceivePackProxiedToGitalySuccessfully(t *testing.T) {
	apiResponse := gitOkBody(t)

	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	apiResponse.GitalyServer.Address = "unix://" + socketPath
	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/git-receive-pack"
	resp, body := httpPost(
		t,
		ws.URL+resource,
		"application/x-git-receive-pack-request",
		testhelper.GitalyReceivePackResponseMock,
	)

	expectedBody := strings.Join([]string{
		apiResponse.Repository.StorageName,
		apiResponse.Repository.RelativePath,
		apiResponse.GL_ID,
		string(testhelper.GitalyReceivePackResponseMock),
	}, "\000")

	assert.Equal(t, 200, resp.StatusCode, "POST %q", resource)
	assert.Equal(t, expectedBody, body, "POST %q: response body", resource)
	testhelper.AssertResponseHeader(t, resp, "Content-Type", "application/x-git-receive-pack-result")
}

func TestPostReceivePackProxiedToGitalyInterrupted(t *testing.T) {
	apiResponse := gitOkBody(t)

	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	apiResponse.GitalyServer.Address = "unix://" + socketPath
	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/git-receive-pack"
	resp, err := http.Post(
		ws.URL+resource,
		"application/x-git-receive-pack-request",
		bytes.NewReader(testhelper.GitalyReceivePackResponseMock),
	)
	require.NoError(t, err)
	assert.Equal(t, 200, resp.StatusCode, "POST %q", resource)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	select {
	case <-done:
		return
	case <-time.After(10 * time.Second):
		t.Fatal("time out waiting for gitaly handler to return")
	}
}

func TestPostUploadPackProxiedToGitalySuccessfully(t *testing.T) {
	apiResponse := gitOkBody(t)

	for _, code := range []codes.Code{codes.OK, codes.Unavailable} {
		func() {
			gitalyServer, socketPath := startGitalyServer(t, code)
			defer gitalyServer.Stop()

			apiResponse.GitalyServer.Address = "unix://" + socketPath
			ts := testAuthServer(nil, 200, apiResponse)
			defer ts.Close()

			ws := startWorkhorseServer(ts.URL)
			defer ws.Close()

			resource := "/gitlab-org/gitlab-test.git/git-upload-pack"
			resp, body := httpPost(
				t,
				ws.URL+resource,
				"application/x-git-upload-pack-request",
				testhelper.GitalyUploadPackResponseMock,
			)

			expectedBody := strings.Join([]string{
				apiResponse.Repository.StorageName,
				apiResponse.Repository.RelativePath,
				string(testhelper.GitalyUploadPackResponseMock),
			}, "\000")

			assert.Equal(t, 200, resp.StatusCode, "POST %q", resource)
			assert.Equal(t, expectedBody, body, "POST %q: response body", resource)
			testhelper.AssertResponseHeader(t, resp, "Content-Type", "application/x-git-upload-pack-result")
		}()
	}
}

func TestPostUploadPackProxiedToGitalyInterrupted(t *testing.T) {
	apiResponse := gitOkBody(t)

	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	apiResponse.GitalyServer.Address = "unix://" + socketPath
	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/git-upload-pack"
	resp, err := http.Post(
		ws.URL+resource,
		"application/x-git-upload-pack-request",
		bytes.NewReader(testhelper.GitalyUploadPackResponseMock),
	)
	require.NoError(t, err)
	assert.Equal(t, 200, resp.StatusCode, "POST %q", resource)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	select {
	case <-done:
		return
	case <-time.After(10 * time.Second):
		t.Fatal("time out waiting for gitaly handler to return")
	}
}

func TestGetInfoRefsHandledLocallyDueToEmptyGitalySocketPath(t *testing.T) {
	gitalyServer, _ := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	apiResponse := gitOkBody(t)
	apiResponse.GitalyServer.Address = ""
	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/info/refs?service=git-upload-pack"
	resp, body := httpGet(t, ws.URL+resource)

	assert.Equal(t, 200, resp.StatusCode, "GET %q", resource)
	assert.NotContains(t, string(testhelper.GitalyInfoRefsResponseMock), body, "GET %q: should not have been proxied to Gitaly", resource)
	testhelper.AssertResponseHeader(t, resp, "Content-Type", "application/x-git-upload-pack-advertisement")
}

func TestPostReceivePackHandledLocallyDueToEmptyGitalySocketPath(t *testing.T) {
	gitalyServer, _ := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	apiResponse := gitOkBody(t)
	apiResponse.GitalyServer.Address = ""
	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/git-receive-pack"
	payload := []byte("This payload should not reach Gitaly")
	resp, body := httpPost(t, ws.URL+resource, "application/x-git-receive-pack-request", payload)

	assert.Equal(t, 200, resp.StatusCode, "POST %q: status code", resource)
	assert.NotContains(t, payload, body, "POST %q: request should not have been proxied to Gitaly", resource)
	testhelper.AssertResponseHeader(t, resp, "Content-Type", "application/x-git-receive-pack-result")
}

func TestPostUploadPackHandledLocallyDueToEmptyGitalySocketPath(t *testing.T) {
	gitalyServer, _ := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	apiResponse := gitOkBody(t)
	apiResponse.GitalyServer.Address = ""
	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/git-upload-pack"
	payload := []byte("This payload should not reach Gitaly")
	resp, body := httpPost(t, ws.URL+resource, "application/x-git-upload-pack-request", payload)

	assert.Equal(t, 200, resp.StatusCode, "POST %q: status code", resource)
	assert.NotContains(t, payload, body, "POST %q: request should not have been proxied to Gitaly", resource)
	testhelper.AssertResponseHeader(t, resp, "Content-Type", "application/x-git-upload-pack-result")
}

func TestGetBlobProxiedToGitalySuccessfully(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	gitalyAddress := "unix://" + socketPath
	repoStorage := "default"
	oid := "54fcc214b94e78d7a41a9a8fe6d87a5e59500e51"
	repoRelativePath := "foo/bar.git"
	jsonParams := fmt.Sprintf(`{"GitalyServer":{"Address":"%s","Token":""},"GetBlobRequest":{"repository":{"storage_name":"%s","relative_path":"%s"},"oid":"%s","limit":-1}}`,
		gitalyAddress, repoStorage, repoRelativePath, oid)
	expectedBody := testhelper.GitalyGetBlobResponseMock
	blobLength := len(expectedBody)

	resp, body, err := doSendDataRequest("/something", "git-blob", jsonParams)
	require.NoError(t, err)

	assert.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
	assert.Equal(t, expectedBody, string(body), "GET %q: response body", resp.Request.URL)
	assert.Equal(t, blobLength, len(body), "GET %q: body size", resp.Request.URL)
	testhelper.AssertResponseHeader(t, resp, "Content-Length", strconv.Itoa(blobLength))
}

func TestGetBlobProxiedToGitalyInterruptedStream(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	gitalyAddress := "unix://" + socketPath
	repoStorage := "default"
	oid := "54fcc214b94e78d7a41a9a8fe6d87a5e59500e51"
	repoRelativePath := "foo/bar.git"
	jsonParams := fmt.Sprintf(`{"GitalyServer":{"Address":"%s","Token":""},"GetBlobRequest":{"repository":{"storage_name":"%s","relative_path":"%s"},"oid":"%s","limit":-1}}`,
		gitalyAddress, repoStorage, repoRelativePath, oid)

	resp, _, err := doSendDataRequest("/something", "git-blob", jsonParams)
	require.NoError(t, err)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	select {
	case <-done:
		return
	case <-time.After(10 * time.Second):
		t.Fatal("time out waiting for gitaly handler to return")
	}
}

type combinedServer struct {
	*grpc.Server
	*testhelper.GitalyTestServer
}

func startGitalyServer(t *testing.T, finalMessageCode codes.Code) (*combinedServer, string) {
	socketPath := path.Join(scratchDir, fmt.Sprintf("gitaly-%d.sock", rand.Int()))
	if err := os.Remove(socketPath); err != nil && !os.IsNotExist(err) {
		t.Fatal(err)
	}
	server := grpc.NewServer()
	listener, err := net.Listen("unix", socketPath)
	require.NoError(t, err)

	gitalyServer := testhelper.NewGitalyServer(finalMessageCode)
	pb.RegisterSmartHTTPServer(server, gitalyServer)
	pb.RegisterBlobServiceServer(server, gitalyServer)

	go server.Serve(listener)

	return &combinedServer{Server: server, GitalyTestServer: gitalyServer}, socketPath
}
