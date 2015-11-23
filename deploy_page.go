package main

import (
	"io/ioutil"
	"log"
	"net/http"
	"path/filepath"
)

func handleDeployPage(deployPage string, handler serviceHandleFunc) serviceHandleFunc {
	deployPage, err := filepath.Abs(deployPage)
	if err != nil {
		log.Fatalln(err)
	}

	return func(w http.ResponseWriter, r *gitRequest) {
		data, err := ioutil.ReadFile(deployPage)
		if err != nil {
			handler(w, r)
			return
		}

		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusOK)
		w.Write(data)
	}
}
