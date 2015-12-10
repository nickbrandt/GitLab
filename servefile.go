package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

func handleServeFile(documentRoot *string, notFoundHandler serviceHandleFunc) serviceHandleFunc {
	return func(w http.ResponseWriter, r *gitRequest) {
		file := filepath.Join(*documentRoot, r.relativeUriPath)

		// The filepath.Join does Clean traversing directories up
		if !strings.HasPrefix(file, *documentRoot) {
			fail500(w, fmt.Errorf("invalid path: "+file, os.ErrInvalid))
			return
		}

		content, fi, err := openFile(file)
		if err != nil {
			if notFoundHandler != nil {
				notFoundHandler(w, r)
			} else {
				http.NotFound(w, r.Request)
			}
			return
		}
		defer content.Close()

		log.Printf("StaticFile: serving %q", file)
		http.ServeContent(w, r.Request, filepath.Base(file), fi.ModTime(), content)
	}
}
