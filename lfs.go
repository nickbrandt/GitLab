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

		if r.LfsSize == 0 {
			fail500(w, "lfsAuthorizeHandler", errors.New("Lfs object size not specified."))
			return
		}

		if err := os.Mkdir(r.StoreLFSPath, 0700); err != nil {
			fail500(w, "Couldn't create directory for storing LFS tmp objects.", err)
			return
		}

		handleFunc(w, r)
	}, "/authorize")
}

func handleStoreLfsObject(w http.ResponseWriter, r *gitRequest) {
	var body io.ReadCloser

	body = r.Body
	defer body.Close()

	file, err := ioutil.TempFile(r.StoreLFSPath, r.LfsOid)
	if err != nil {
		fail500(w, "Couldn't open tmp file for writing.", err)
		return
	}
	defer os.Remove(file.Name())
	defer file.Close()

	hash := sha256.New()
	hw := io.MultiWriter(hash, file)

	written, err := io.Copy(hw, body)
	if err != nil {
		fail500(w, "Failed to save received LFS object.", err)
		return
	}
	file.Close()

	if written != r.LfsSize {
		fail500(w, "Inconsistent size: ", errSizeMismatch)
		return
	}

	shaStr := hex.EncodeToString(hash.Sum(nil))
	if shaStr != r.LfsOid {
		fail500(w, "Inconsistent size: ", errSizeMismatch)
		return
	}
	r.Header.Set("X-GitLab-Lfs-Tmp", filepath.Base(file.Name()))

	authReq, err := r.u.newUpstreamRequest(r.Request, nil, "")
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
