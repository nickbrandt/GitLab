package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "Yes")
	})

	log.Fatal(http.ListenAndServe("localhost:8080", nil))
}
