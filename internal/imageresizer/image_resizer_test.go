package imageresizer

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

var r = resizer{}

func TestUnpackParametersReturnsParamsInstanceForValidInput(t *testing.T) {
	inParams := resizeParams{Location: "/path/to/img", Width: 64, ContentType: "image/png"}

	outParams, err := r.unpackParameters(encodeParams(t, &inParams))

	require.NoError(t, err, "unexpected error when unpacking params")
	require.Equal(t, inParams, *outParams)
}

func TestUnpackParametersReturnsErrorWhenLocationBlank(t *testing.T) {
	inParams := resizeParams{Location: "", Width: 64, ContentType: "image/jpg"}

	_, err := r.unpackParameters(encodeParams(t, &inParams))

	require.Error(t, err, "expected error when Location is blank")
}

func TestUnpackParametersReturnsErrorWhenContentTypeBlank(t *testing.T) {
	inParams := resizeParams{Location: "/path/to/img", Width: 64, ContentType: ""}

	_, err := r.unpackParameters(encodeParams(t, &inParams))

	require.Error(t, err, "expected error when ContentType is blank")
}

func TestDetermineFilePrefixFromMimeType(t *testing.T) {
	require.Equal(t, "png:", determineFilePrefix("image/png"))
	require.Equal(t, "jpg:", determineFilePrefix("image/jpeg"))
	require.Equal(t, "", determineFilePrefix("unsupported"))
}

func TestTryResizeImageSuccess(t *testing.T) {
	inParams := resizeParams{Location: "/path/to/img", Width: 64, ContentType: "image/png"}
	inFile := testImage(t)
	req, err := http.NewRequest("GET", "/foo", nil)
	require.NoError(t, err)

	reader, cmd, err := tryResizeImage(req, inFile, os.Stderr, &inParams)

	require.NoError(t, err)
	require.NotNil(t, cmd)
	require.NotNil(t, reader)
	require.NotEqual(t, inFile, reader)
}

func TestTryResizeImageFailsOverToOriginalImageWhenContentTypeNotSupported(t *testing.T) {
	inParams := resizeParams{Location: "/path/to/img", Width: 64, ContentType: "not supported"}
	inFile := testImage(t)
	req, err := http.NewRequest("GET", "/foo", nil)
	require.NoError(t, err)

	reader, cmd, err := tryResizeImage(req, inFile, os.Stderr, &inParams)

	require.Error(t, err)
	require.Nil(t, cmd)
	require.Equal(t, inFile, reader)
}

func TestGraphicsMagickFailsWhenContentTypeNotMatchingFileContents(t *testing.T) {
	inParams := resizeParams{Location: "/path/to/img", Width: 64, ContentType: "image/jpeg"}
	inFile := testImage(t) // this is PNG file; gm should fail fast in this case
	req, err := http.NewRequest("GET", "/foo", nil)
	require.NoError(t, err)

	_, cmd, err := tryResizeImage(req, inFile, os.Stderr, &inParams)

	require.NoError(t, err)
	require.Error(t, cmd.Wait())
}

// The Rails applications sends a Base64 encoded JSON string carrying
// these parameters in an HTTP response header
func encodeParams(t *testing.T, p *resizeParams) string {
	json, err := json.Marshal(*p)
	if err != nil {
		require.NoError(t, err, "JSON encoder encountered unexpected error")
	}
	return base64.StdEncoding.EncodeToString(json)
}

func testImage(t *testing.T) *os.File {
	f, err := os.Open("../../testdata/image.png")
	require.NoError(t, err)
	return f
}
