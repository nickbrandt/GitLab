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
	"net/http"
	"os"
	"path/filepath"
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

		if r.LfsOid == "" {
			fail500(w, "lfsAuthorizeHandler", errors.New("Lfs object oid not specified."))
			return
		}

		if r.LfsSize == "" {
			fail500(w, "lfsAuthorizeHandler", errors.New("Lfs object size not specified."))
			return
		}

		tmpDir := r.StoreLFSPath
		if _, err := os.Stat(tmpDir); os.IsNotExist(err) {
			if err := os.Mkdir(tmpDir, 0700); err != nil {
				fail500(w, "Couldn't create directory for storing LFS tmp objects.", err)
				return
			}
		}

		handleFunc(w, r)
	}, "")
}

func handleStoreLfsObject(handleFunc serviceHandleFunc) serviceHandleFunc {
	return func(w http.ResponseWriter, r *gitRequest) {
		oid := r.LfsOid
		size := r.LfsSize

		var body io.ReadCloser

		body = r.Body
		defer body.Close()

		tmpPath := r.StoreLFSPath
		file, err := ioutil.TempFile(tmpPath, "")
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
