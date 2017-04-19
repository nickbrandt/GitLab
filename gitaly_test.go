package main

import (
	"fmt"
	"math/rand"
	"net"
	"os"
	"os/exec"
	"path"
	"strings"
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
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
		GitalyAddress: "unix:/nonexistent",
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
	apiResponse := gitOkBody(t)
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	gitalyAddress := "unix://" + socketPath
	apiResponse.GitalyAddress = gitalyAddress

	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/info/refs?service=git-upload-pack"
	_, body := httpGet(t, ws.URL+resource)

	expectedContent := string(testhelper.GitalyInfoRefsResponseMock)
	assert.Equal(t, expectedContent, body, "GET %q: response body", resource)
}

func TestPostReceivePackProxiedToGitalySuccessfully(t *testing.T) {
	apiResponse := gitOkBody(t)

	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	apiResponse.GitalyAddress = "unix://" + socketPath
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
		apiResponse.RepoPath,
		apiResponse.Repository.StorageName,
		apiResponse.Repository.RelativePath,
		apiResponse.GL_ID,
		string(testhelper.GitalyReceivePackResponseMock),
	}, "\000")

	assert.Equal(t, 200, resp.StatusCode, "POST %q", resource)
	assert.Equal(t, expectedBody, body, "POST %q: response body", resource)
	testhelper.AssertResponseHeader(t, resp, "Content-Type", "application/x-git-receive-pack-result")
}

func TestPostUploadPackProxiedToGitalySuccessfully(t *testing.T) {
	apiResponse := gitOkBody(t)

	for _, code := range []codes.Code{codes.OK, codes.Unavailable} {
		func() {
			gitalyServer, socketPath := startGitalyServer(t, code)
			defer gitalyServer.Stop()

			apiResponse.GitalyAddress = "unix://" + socketPath
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
				apiResponse.RepoPath,
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

func TestGetInfoRefsHandledLocallyDueToEmptyGitalySocketPath(t *testing.T) {
	gitalyServer, _ := startGitalyServer(t, codes.OK)
	defer gitalyServer.Stop()

	apiResponse := gitOkBody(t)
	apiResponse.GitalyAddress = ""
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
	apiResponse.GitalyAddress = ""
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
	apiResponse.GitalyAddress = ""
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

func startGitalyServer(t *testing.T, code codes.Code) (*grpc.Server, string) {
	socketPath := path.Join(scratchDir, fmt.Sprintf("gitaly-%d.sock", rand.Int()))
	server := grpc.NewServer()
	listener, err := net.Listen("unix", socketPath)
	require.NoError(t, err)

	pb.RegisterSmartHTTPServer(server, testhelper.NewGitalyServer(code))

	go server.Serve(listener)

	return server, socketPath
}
