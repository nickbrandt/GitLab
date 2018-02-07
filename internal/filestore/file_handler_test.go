package filestore_test

import (
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/filestore"
)

// Some usefull const for testing purpose
const (
	// testContent an example textual content
	testContent = "TEST OBJECT CONTENT"
	// testSize is the testContent size
	testSize = int64(len(testContent))
	// testMD5 is testContent MD5 hash
	testMD5 = "42d000eea026ee0760677e506189cb33"
	// testSHA256 is testContent SHA256 hash
	testSHA256 = "b0257e9e657ef19b15eed4fbba975bd5238d651977564035ef91cb45693647aa"
)

func TestSaveFileFromReader(t *testing.T) {
	assert := assert.New(t)
	require := require.New(t)

	tmpFolder, err := ioutil.TempDir("", "workhorse-test-tmp")
	require.NoError(err)
	defer os.RemoveAll(tmpFolder)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	opts := &filestore.SaveFileOpts{LocalTempPath: tmpFolder, TempFilePrefix: "test-file"}
	fh, err := filestore.SaveFileFromReader(ctx, strings.NewReader(testContent), testSize, opts)
	assert.NoError(err)
	require.NotNil(fh)

	assert.NotEmpty(fh.LocalPath, "File hasn't been persisted on disk")
	_, err = os.Stat(fh.LocalPath)
	assert.NoError(err)

	assert.Equal(testMD5, fh.MD5())
	assert.Equal(testSHA256, fh.SHA256())

	cancel()
	time.Sleep(100 * time.Millisecond)
	_, err = os.Stat(fh.LocalPath)
	assert.Error(err)
	assert.True(os.IsNotExist(err), "File hasn't been deleted during cleanup")
}

func TestSaveFileWrongSize(t *testing.T) {
	assert := assert.New(t)
	require := require.New(t)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	tmpFolder, err := ioutil.TempDir("", "workhorse-test-tmp")
	require.NoError(err)
	defer os.RemoveAll(tmpFolder)

	opts := &filestore.SaveFileOpts{LocalTempPath: tmpFolder, TempFilePrefix: "test-file"}
	fh, err := filestore.SaveFileFromReader(ctx, strings.NewReader(testContent), testSize+1, opts)
	assert.Error(err)
	assert.EqualError(err, fmt.Sprintf("Expected %d bytes but got only %d", testSize+1, testSize))
	assert.Nil(fh)
}
