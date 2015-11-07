/*
In this file we handle git lfs objects downloads and uploads
*/

package main

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"io/ioutil"
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

func lfsAuthorizeHandler(handleFunc serviceHandleFunc) serviceHandleFunc {
	return preAuthorizeHandler(func(w http.ResponseWriter, r *gitRequest) {

		if r.StoreLFSPath == "" {
			fail500(w, "lfsAuthorizeHandler", errors.New("Don't know where to store object, no store path specified."))
			return
		}

		handleFunc(w, r)
	}, "")
}

func handleStoreLfsObject(handleFunc serviceHandleFunc) serviceHandleFunc {
	return func(w http.ResponseWriter, r *gitRequest) {

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

		sha := sha256.New()
		sha.Write([]byte(oid))
		tmp_hash := hex.EncodeToString(sha.Sum(nil))
		tmpPath := filepath.Join(r.StoreLFSPath, "tmp")

		var body io.ReadCloser

		body = r.Body
		defer body.Close()

		dir := filepath.Dir(tmpPath)
		if err := os.MkdirAll(dir, 0700); err != nil {
			fail500(w, "Couldn't create directory for storing LFS objects.", err)
			return
		}

		file, err := ioutil.TempFile(tmpPath, tmp_hash)
		if err != nil {
			fail500(w, "Couldn't open tmp file for writing.", err)
			return
		}
		defer os.Remove(tmpPath)
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
		r.Header.Set("X-GitLab-Lfs-Tmp", filepath.Base(file.Name()))

		handleFunc(w, r)
	}
}

func lfsCallback(w http.ResponseWriter, r *gitRequest) {
	authReq, err := r.u.newUpstreamRequest(r.Request, nil, "/authorize")
	if err != nil {
		fail500(w, "newUpstreamRequestlfsCallback", err)
		return
	}

	authResponse, err := r.u.httpClient.Do(authReq)
	if err != nil {
		fail500(w, "doRequestlfsCallback", err)
		return
	}
	defer authResponse.Body.Close()
	return
}
