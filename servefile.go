package main

import (
	"./internal/helper"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type CacheMode int

const (
	CacheDisabled CacheMode = iota
	CacheExpireMax
)

func (u *upstream) handleServeFile(documentRoot *string, cache CacheMode, notFoundHandler httpHandleFunc) httpHandleFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		file := filepath.Join(*documentRoot, u.relativeURIPath(cleanURIPath(r.URL.Path)))

		// The filepath.Join does Clean traversing directories up
		if !strings.HasPrefix(file, *documentRoot) {
			fail500(w, &os.PathError{
				Op:   "open",
				Path: file,
				Err:  os.ErrInvalid,
			})
			return
		}

		var content *os.File
		var fi os.FileInfo
		var err error

		// Serve pre-gzipped assets
		if acceptEncoding := r.Header.Get("Accept-Encoding"); strings.Contains(acceptEncoding, "gzip") {
			content, fi, err = helper.OpenFile(file + ".gz")
			if err == nil {
				w.Header().Set("Content-Encoding", "gzip")
			}
		}

		// If not found, open the original file
		if content == nil || err != nil {
			content, fi, err = helper.OpenFile(file)
		}
		if err != nil {
			if notFoundHandler != nil {
				notFoundHandler(w, r)
			} else {
				http.NotFound(w, r)
			}
			return
		}
		defer content.Close()

		switch cache {
		case CacheExpireMax:
			// Cache statically served files for 1 year
			cacheUntil := time.Now().AddDate(1, 0, 0).Format(http.TimeFormat)
			w.Header().Set("Cache-Control", "public")
			w.Header().Set("Expires", cacheUntil)
		}

		log.Printf("Send static file %q (%q) for %s %q", file, w.Header().Get("Content-Encoding"), r.Method, r.RequestURI)
		http.ServeContent(w, r, filepath.Base(file), fi.ModTime(), content)
	}
}
