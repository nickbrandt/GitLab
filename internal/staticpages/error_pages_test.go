package staticpages

import (
	"../testhelper"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

func TestIfErrorPageIsPresented(t *testing.T) {
	dir, err := ioutil.TempDir("", "error_page")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	errorPage := "ERROR"
	ioutil.WriteFile(filepath.Join(dir, "404.html"), []byte(errorPage), 0600)

	w := httptest.NewRecorder()
	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(404)
		fmt.Fprint(w, "Not Found")
	})
	st := &Static{dir}
	st.ErrorPagesUnless(false, h).ServeHTTP(w, nil)
	w.Flush()

	testhelper.AssertResponseCode(t, w, 404)
	testhelper.AssertResponseBody(t, w, errorPage)
}

func TestIfErrorPassedIfNoErrorPageIsFound(t *testing.T) {
	dir, err := ioutil.TempDir("", "error_page")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	w := httptest.NewRecorder()
	errorResponse := "ERROR"
	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(404)
		fmt.Fprint(w, errorResponse)
	})
	st := &Static{dir}
	st.ErrorPagesUnless(false, h).ServeHTTP(w, nil)
	w.Flush()

	testhelper.AssertResponseCode(t, w, 404)
	testhelper.AssertResponseBody(t, w, errorResponse)
}

func TestIfErrorPageIsIgnoredInDevelopment(t *testing.T) {
	dir, err := ioutil.TempDir("", "error_page")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	errorPage := "ERROR"
	ioutil.WriteFile(filepath.Join(dir, "500.html"), []byte(errorPage), 0600)

	w := httptest.NewRecorder()
	serverError := "Interesting Server Error"
	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(500)
		fmt.Fprint(w, serverError)
	})
	st := &Static{dir}
	st.ErrorPagesUnless(true, h).ServeHTTP(w, nil)
	w.Flush()
	testhelper.AssertResponseCode(t, w, 500)
	testhelper.AssertResponseBody(t, w, serverError)
}
