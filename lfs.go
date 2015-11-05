/*
In this file we handle git lfs objects downloads and uploads
*/

package main

import (
	"compress/gzip"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
)

var (
	errHashMismatch = errors.New("Content hash does not match OID")
	errSizeMismatch = errors.New("Content size does not match")
)

func handleStoreLfsObject(w http.ResponseWriter, r *gitRequest, rpc string) {
	var body io.ReadCloser

	urlPath := r.URL.Path
	regExp := regexp.MustCompile(`([0-9a-f]{64})/([0-9]+)`)
	matches := regExp.FindStringSubmatch(urlPath)

	if matches == nil {
		log.Printf("Found no object info in path: %s", urlPath)
		return
	}

	oid := matches[1]
	size := matches[2]
	log.Printf("Found oid: %s and size: %s", oid, size)

	storePath := filepath.Join(r.StoreLFSPath, transformKey(oid))

	if _, err := os.Stat(storePath); os.IsNotExist(err) {
		tmpPath := filepath.Join(r.StoreLFSPath, "tmp", oid)

		if _, err := os.Stat(tmpPath); os.IsNotExist(err) {
			// TODO try removing gzip, possibly not needed
			// The client request body may have been gzipped.
			if r.Header.Get("Content-Encoding") == "gzip" {
				body, err = gzip.NewReader(r.Body)
				if err != nil {
					fail500(w, "Couldn't handle LFS upload request.", err)
					return
				}
			} else {
				body = r.Body
			}
			defer body.Close()

			// TODO maybe set dir permissions to 700
			dir := filepath.Dir(tmpPath)
			if err := os.MkdirAll(dir, 0750); err != nil {
				fail500(w, "Couldn't create directory for storing LFS objects.", err)
				return
			}

			// TODO use go library for creating TMP files
			file, err := os.OpenFile(tmpPath, os.O_CREATE|os.O_WRONLY|os.O_EXCL, 0640)
			if err != nil {
				fail500(w, "Couldn't open tmp file for writing.", err)
				return
			}
			// defer os.Remove(tmpPath)
			defer file.Close()

			hash := sha256.New()
			hw := io.MultiWriter(hash, file)

			written, err := io.Copy(hw, body)
			if err != nil {
				fail500(w, "Failed to save received LFS object.", err)
				return
			}
			file.Close()

			sizeInt, err := strconv.ParseInt(size, 10, 64)
			if err != nil {
				fail500(w, "Couldn't read size: ", err)
				return
			}

			if written != sizeInt {
				fail500(w, "Inconsistent size: ", errSizeMismatch)
				return
			}

			shaStr := hex.EncodeToString(hash.Sum(nil))
			if shaStr != oid {
				fail500(w, "Inconsistent size: ", errSizeMismatch)
				return
			}
		}
	}
	// if err := os.Rename(tmpPath, path); err != nil {
	// 	fail500(w, "Failed to rename temporary LFS object.", err)
	// 	return
	// }

	log.Printf("Received the LFS object from client, oid: %s", oid)

	return

}

func handleRetreiveLfsObject(w http.ResponseWriter, r *gitRequest, rpc string) {
	log.Printf("I should download %s", r)

	urlPath := r.URL.Path
	regExp := regexp.MustCompile(`([0-9a-f]{64})\z`)
	oid := regExp.FindString(urlPath)

	if len(oid) == 0 {
		log.Printf("Found no object for download: %s", urlPath)
		return
	}

	log.Printf("Found oid: %s", oid)
	path := filepath.Join(r.StoreLFSPath, transformKey(oid))

	content, err := os.Open(path)
	if err != nil {
		fail500(w, "Cannot get file: ", err)
		return
	}
	defer content.Close()

	io.Copy(w, content)

	log.Printf("Sent the LFS object to client, oid: %s", oid)

	return
}

func transformKey(key string) string {
	if len(key) < 5 {
		return key
	}

	return filepath.Join(key[0:2], key[2:4], key[4:len(key)])
}
