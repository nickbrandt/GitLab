package helper

import (
	"errors"
	"log"
	"net/http"
	"os"
)

func Fail500(w http.ResponseWriter, err error) {
	http.Error(w, "Internal server error", 500)
	LogError(err)
}

func LogError(err error) {
	log.Printf("error: %v", err)
}

func SetNoCacheHeaders(header http.Header) {
	header.Set("Cache-Control", "no-cache, no-store, max-age=0, must-revalidate")
	header.Set("Pragma", "no-cache")
	header.Set("Expires", "Fri, 01 Jan 1990 00:00:00 GMT")
}

func OpenFile(path string) (file *os.File, fi os.FileInfo, err error) {
	file, err = os.Open(path)
	if err != nil {
		return
	}

	defer func() {
		if err != nil {
			file.Close()
		}
	}()

	fi, err = file.Stat()
	if err != nil {
		return
	}

	// The os.Open can also open directories
	if fi.IsDir() {
		err = &os.PathError{
			Op:   "open",
			Path: path,
			Err:  errors.New("path is directory"),
		}
		return
	}

	return
}
