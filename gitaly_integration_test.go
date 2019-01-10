// Tests in this file need access to a real Gitaly server to run. The address
// is supplied via the GITALY_ADDRESS environment variable
package main

import (
	"archive/tar"
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path"
	"strconv"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/gitaly-proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
)

var (
	gitalyAddress    string
	jsonGitalyServer string
)

func init() {
	gitalyAddress = os.Getenv("GITALY_ADDRESS")
	jsonGitalyServer = fmt.Sprintf(`"GitalyServer":{"Address":"%s", "Token": ""}`, gitalyAddress)
}

func skipUnlessRealGitaly(t *testing.T) {
	t.Log(gitalyAddress)
	if gitalyAddress != "" {
		return
	}

	t.Skip(`Please set GITALY_ADDRESS="..." to run Gitaly integration tests`)
}

func realGitalyAuthResponse(apiResponse *api.Response) *api.Response {
	apiResponse.GitalyServer.Address = gitalyAddress

	return apiResponse
}

func realGitalyOkBody(t *testing.T) *api.Response {
	return realGitalyAuthResponse(gitOkBody(t))
}

func ensureGitalyRepository(t *testing.T, apiResponse *api.Response) error {
	namespace, err := gitaly.NewNamespaceClient(apiResponse.GitalyServer)
	if err != nil {
		return err
	}
	repository, err := gitaly.NewRepositoryClient(apiResponse.GitalyServer)
	if err != nil {
		return err
	}

	// Remove the repository if it already exists, for consistency
	rmNsReq := &gitalypb.RemoveNamespaceRequest{
		StorageName: apiResponse.Repository.StorageName,
		Name:        apiResponse.Repository.RelativePath,
	}
	_, err = namespace.RemoveNamespace(context.Background(), rmNsReq)
	if err != nil {
		return err
	}

	createReq := &gitalypb.CreateRepositoryFromURLRequest{
		Repository: &apiResponse.Repository,
		Url:        "https://gitlab.com/gitlab-org/gitlab-test.git",
	}

	_, err = repository.CreateRepositoryFromURL(context.Background(), createReq)
	return err
}

func TestAllowedClone(t *testing.T) {
	skipUnlessRealGitaly(t)

	// Create the repository in the Gitaly server
	apiResponse := realGitalyOkBody(t)
	require.NoError(t, ensureGitalyRepository(t, apiResponse))

	// Prepare test server and backend
	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Do the git clone
	require.NoError(t, os.RemoveAll(scratchDir))
	cloneCmd := exec.Command("git", "clone", fmt.Sprintf("%s/%s", ws.URL, testRepo), checkoutDir)
	runOrFail(t, cloneCmd)

	// We may have cloned an 'empty' repository, 'git log' will fail in it
	logCmd := exec.Command("git", "log", "-1", "--oneline")
	logCmd.Dir = checkoutDir
	runOrFail(t, logCmd)
}

func TestAllowedShallowClone(t *testing.T) {
	skipUnlessRealGitaly(t)

	// Create the repository in the Gitaly server
	apiResponse := realGitalyOkBody(t)
	require.NoError(t, ensureGitalyRepository(t, apiResponse))

	// Prepare test server and backend
	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Shallow git clone (depth 1)
	require.NoError(t, os.RemoveAll(scratchDir))
	cloneCmd := exec.Command("git", "clone", "--depth", "1", fmt.Sprintf("%s/%s", ws.URL, testRepo), checkoutDir)
	runOrFail(t, cloneCmd)

	// We may have cloned an 'empty' repository, 'git log' will fail in it
	logCmd := exec.Command("git", "log", "-1", "--oneline")
	logCmd.Dir = checkoutDir
	runOrFail(t, logCmd)
}

func TestAllowedPush(t *testing.T) {
	skipUnlessRealGitaly(t)

	// Create the repository in the Gitaly server
	apiResponse := realGitalyOkBody(t)
	require.NoError(t, ensureGitalyRepository(t, apiResponse))

	// Prepare the test server and backend
	ts := testAuthServer(nil, 200, apiResponse)
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Perform the git push
	pushCmd := exec.Command("git", "push", fmt.Sprintf("%s/%s", ws.URL, testRepo), fmt.Sprintf("master:%s", newBranch()))
	pushCmd.Dir = checkoutDir
	runOrFail(t, pushCmd)
}

func TestAllowedGetGitBlob(t *testing.T) {
	skipUnlessRealGitaly(t)

	// Create the repository in the Gitaly server
	apiResponse := realGitalyOkBody(t)
	require.NoError(t, ensureGitalyRepository(t, apiResponse))

	// the LICENSE file in the test repository
	oid := "50b27c6518be44c42c4d87966ae2481ce895624c"
	expectedBody := "The MIT License (MIT)"
	bodyLen := 1075

	jsonParams := fmt.Sprintf(
		`{
			%s,
			"GetBlobRequest":{
				"repository":{"storage_name":"%s", "relative_path":"%s"},
				"oid":"%s",
				"limit":-1
			}
		}`,
		jsonGitalyServer, apiResponse.Repository.StorageName, apiResponse.Repository.RelativePath, oid,
	)

	resp, body, err := doSendDataRequest("/something", "git-blob", jsonParams)
	require.NoError(t, err)
	shortBody := string(body[:len(expectedBody)])

	assert.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
	assert.Equal(t, expectedBody, shortBody, "GET %q: response body", resp.Request.URL)
	testhelper.AssertResponseHeader(t, resp, "Content-Length", strconv.Itoa(bodyLen))
	assertNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resp.Request.URL)
}

func TestAllowedGetGitArchive(t *testing.T) {
	skipUnlessRealGitaly(t)

	// Create the repository in the Gitaly server
	apiResponse := realGitalyOkBody(t)
	repo := apiResponse.Repository
	require.NoError(t, ensureGitalyRepository(t, apiResponse))

	archivePath := path.Join(scratchDir, "my/path")
	archivePrefix := "repo-1"

	jsonParams := fmt.Sprintf(
		`{
			%s,
			"GitalyRepository":{"storage_name":"%s","relative_path":"%s"},
			"ArchivePath":"%s",
			"ArchivePrefix":"%s",
			"CommitId":"%s"
		}`,
		jsonGitalyServer, repo.StorageName, repo.RelativePath, archivePath, archivePrefix, "HEAD",
	)

	resp, body, err := doSendDataRequest("/archive.tar", "git-archive", jsonParams)
	require.NoError(t, err)
	assert.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
	assertNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resp.Request.URL)

	// Ensure the tar file is readable
	foundEntry := false
	tr := tar.NewReader(bytes.NewReader(body))
	for {
		hdr, err := tr.Next()
		if err != nil {
			break
		}

		if hdr.Name == archivePrefix+"/" {
			foundEntry = true
			break
		}
	}

	assert.True(t, foundEntry, "Couldn't find %v directory entry", archivePrefix)
}

func TestAllowedGetGitDiff(t *testing.T) {
	skipUnlessRealGitaly(t)

	// Create the repository in the Gitaly server
	apiResponse := realGitalyOkBody(t)
	require.NoError(t, ensureGitalyRepository(t, apiResponse))

	leftCommit := "8a0f2ee90d940bfb0ba1e14e8214b0649056e4ab"
	rightCommit := "e395f646b1499e8e0279445fc99a0596a65fab7e"
	expectedBody := "diff --git a/README.md b/README.md"

	msg := serializedMessage("RawDiffRequest", &gitalypb.RawDiffRequest{
		Repository:    &apiResponse.Repository,
		LeftCommitId:  leftCommit,
		RightCommitId: rightCommit,
	})
	jsonParams := buildGitalyRPCParams(gitalyAddress, msg)

	resp, body, err := doSendDataRequest("/something", "git-diff", jsonParams)
	require.NoError(t, err)
	shortBody := string(body[:len(expectedBody)])

	assert.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
	assert.Equal(t, expectedBody, shortBody, "GET %q: response body", resp.Request.URL)
	assertNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resp.Request.URL)
}

func TestAllowedGetGitFormatPatch(t *testing.T) {
	skipUnlessRealGitaly(t)

	// Create the repository in the Gitaly server
	apiResponse := realGitalyOkBody(t)
	require.NoError(t, ensureGitalyRepository(t, apiResponse))

	leftCommit := "8a0f2ee90d940bfb0ba1e14e8214b0649056e4ab"
	rightCommit := "e395f646b1499e8e0279445fc99a0596a65fab7e"
	msg := serializedMessage("RawPatchRequest", &gitalypb.RawPatchRequest{
		Repository:    &apiResponse.Repository,
		LeftCommitId:  leftCommit,
		RightCommitId: rightCommit,
	})
	jsonParams := buildGitalyRPCParams(gitalyAddress, msg)

	resp, body, err := doSendDataRequest("/something", "git-format-patch", jsonParams)
	require.NoError(t, err)

	assert.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
	assertNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resp.Request.URL)

	testhelper.AssertPatchSeries(
		t,
		body,
		"372ab6950519549b14d220271ee2322caa44d4eb",
		"57290e673a4c87f51294f5216672cbc58d485d25",
		"41ae11ba5d091d73d5de671f6fa7d1a4539e979e",
		"742518b2be68fc750bb4c357c0df821a88113286",
		rightCommit,
	)
}
