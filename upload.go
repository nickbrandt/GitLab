package main

import (
	"fmt"
	"net/http"
	"os"
	"path"
)

func handleGetUpload(w http.ResponseWriter, r *gitRequest, _ string) {
	if r.ContentDisposition == "attachment" {
		w.Header().Add("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, path.Base(r.ContentPath)))
	} else {
		w.Header().Add("Content-Disposition", r.ContentDisposition)
	}

	f, err := os.Open(r.ContentPath)
	if err != nil {
		logContext("handleGetUpload open file", err)
		http.Error(w, "Not Found", 404)
		return
	}
	defer f.Close()

	fi, err := f.Stat()
	if err != nil {
		fail500(w, "handleGetUpload get mtime", err)
		return
	}
	http.ServeContent(w, r.Request, "", fi.ModTime(), f)
}
