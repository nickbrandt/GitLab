package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

func handleServeFile(rootDir string, notFoundHandler serviceHandleFunc) serviceHandleFunc {
	rootDir, err := filepath.Abs(rootDir)
	if err != nil {
		log.Fatalln(err)
	}

	return func(w http.ResponseWriter, r *gitRequest) {
		file := filepath.Join(rootDir, r.URL.Path)
		file, err := filepath.Abs(file)
		if err != nil {
			fail500(w, fmt.Errorf("invalid path:"+file, err))
			return
		}

		if !strings.HasPrefix(file, rootDir) {
			fail500(w, fmt.Errorf("invalid path: "+file, os.ErrInvalid))
			return
		}

		content, err := os.Open(file)
		if err != nil {
			if notFoundHandler != nil {
				notFoundHandler(w, r)
			} else {
				http.NotFound(w, r.Request)
			}
			return
		}
		defer content.Close()

		fi, err := content.Stat()
		if err != nil {
			fail500(w, fmt.Errorf("handleServeFileHandler", err))
			return
		}

		if fi.IsDir() {
			if notFoundHandler != nil {
				notFoundHandler(w, r)
			} else {
				http.NotFound(w, r.Request)
			}
			return
		}

		log.Printf("StaticFile: serving %q", file)
		http.ServeContent(w, r.Request, filepath.Base(file), fi.ModTime(), content)
	}
}
