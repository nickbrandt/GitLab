package senddata

import (
	"io"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestHeaderDelete(t *testing.T) {
	for _, code := range []int{200, 400} {
		recorder := httptest.NewRecorder()
		rw := &sendDataResponseWriter{rw: recorder, req: &http.Request{}}
		rw.Header().Set(HeaderKey, "foobar")
		rw.WriteHeader(code)

		if header := recorder.Header().Get(HeaderKey); header != "" {
			t.Fatalf("HTTP %d response: expected header to be empty, found %q", code, header)
		}
	}
}

func TestWriter(t *testing.T) {
	upstreamResponse := "hello world"

	testCases := []struct {
		desc        string
		headerValue string
		out         string
	}{
		{
			desc:        "inject",
			headerValue: testInjecterName + ":" + testInjecterName,
			out:         testInjecterData,
		},
		{
			desc:        "pass",
			headerValue: "",
			out:         upstreamResponse,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			recorder := httptest.NewRecorder()
			rw := &sendDataResponseWriter{rw: recorder, injecters: []Injecter{&testInjecter{}}}

			rw.Header().Set(HeaderKey, tc.headerValue)

			n, err := rw.Write([]byte(upstreamResponse))
			require.NoError(t, err)
			require.Equal(t, len(upstreamResponse), n, "bytes written")

			recorder.Flush()

			body := recorder.Result().Body
			data, err := ioutil.ReadAll(body)
			require.NoError(t, err)
			require.NoError(t, body.Close())

			require.Equal(t, tc.out, string(data))
		})
	}
}

const (
	testInjecterName = "test-injecter"
	testInjecterData = "hello this is injected data"
)

type testInjecter struct{}

func (ti *testInjecter) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	io.WriteString(w, testInjecterData)
}

func (ti *testInjecter) Match(s string) bool { return strings.HasPrefix(s, testInjecterName+":") }
func (ti *testInjecter) Name() string        { return testInjecterName }
