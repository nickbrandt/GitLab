package helper

import (
	"io"
	"io/ioutil"
	"os"
)

func ReadAllTempfile(r io.Reader) (_ io.ReadCloser, err error) {
	tempfile, err := ioutil.TempFile("", "gitlab-workhorse-read-all-tempfile")
	if err != nil {
		return nil, err
	}
	defer func() {
		if err != nil {
			tempfile.Close()
		}
	}()

	if err := os.Remove(tempfile.Name()); err != nil {
		return nil, err
	}

	if _, err := io.Copy(tempfile, r); err != nil {
		return nil, err
	}

	if _, err := tempfile.Seek(0, 0); err != nil {
		return nil, err
	}

	return tempfile, nil
}
