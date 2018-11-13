package sendfile

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestResponseWriter(t *testing.T) {
	upstreamResponse := "hello world"

	fixturePath := "testdata/sent-file.txt"
	fixtureContent, err := ioutil.ReadFile(fixturePath)
	require.NoError(t, err)

	testCases := []struct {
		desc           string
		sendfileHeader string
		out            string
	}{
		{
			desc:           "send a file",
			sendfileHeader: fixturePath,
			out:            string(fixtureContent),
		},
		{
			desc:           "pass through unaltered",
			sendfileHeader: "",
			out:            upstreamResponse,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			r, err := http.NewRequest("GET", "/foo", nil)
			require.NoError(t, err)

			rw := httptest.NewRecorder()
			sf := &sendFileResponseWriter{rw: rw, req: r}
			sf.Header().Set(sendFileResponseHeader, tc.sendfileHeader)

			upstreamBody := []byte(upstreamResponse)
			n, err := sf.Write(upstreamBody)
			require.NoError(t, err)
			require.Equal(t, len(upstreamBody), n, "bytes written")

			rw.Flush()

			body := rw.Result().Body
			data, err := ioutil.ReadAll(body)
			require.NoError(t, err)
			require.NoError(t, body.Close())

			require.Equal(t, tc.out, string(data))
		})
	}
}
