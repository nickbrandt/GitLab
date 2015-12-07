/*
In this file we handle git lfs objects downloads and uploads
*/

package main

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
)

func lfsAuthorizeHandler(handleFunc serviceHandleFunc) serviceHandleFunc {
	return preAuthorizeHandler(func(w http.ResponseWriter, r *gitRequest) {

		if r.StoreLFSPath == "" {
			fail500(w, errors.New("lfsAuthorizeHandler: StoreLFSPath empty"))
			return
		}

		if r.LfsOid == "" {
			fail500(w, errors.New("lfsAuthorizeHandler: LfsOid empty"))
			return
		}

		if err := os.MkdirAll(r.StoreLFSPath, 0700); err != nil {
			fail500(w, fmt.Errorf("lfsAuthorizeHandler: mkdir StoreLFSPath: %v", err))
			return
		}

		handleFunc(w, r)
	}, "/authorize")
}

func handleStoreLfsObject(w http.ResponseWriter, r *gitRequest) {
	file, err := ioutil.TempFile(r.StoreLFSPath, r.LfsOid)
	if err != nil {
		fail500(w, fmt.Errorf("handleStoreLfsObject: create tempfile: %v", err))
		return
	}
	defer os.Remove(file.Name())
	defer file.Close()

	hash := sha256.New()
	hw := io.MultiWriter(hash, file)

	written, err := io.Copy(hw, r.Body)
	if err != nil {
		fail500(w, fmt.Errorf("handleStoreLfsObject: write tempfile: %v", err))
		return
	}
	file.Close()

	if written != r.LfsSize {
		fail500(w, fmt.Errorf("handleStoreLfsObject: expected size %d, wrote %d", r.LfsSize, written))
		return
	}

	shaStr := hex.EncodeToString(hash.Sum(nil))
	if shaStr != r.LfsOid {
		fail500(w, fmt.Errorf("handleStoreLfsObject: expected sha256 %s, got %s", r.LfsOid, shaStr))
		return
	}
	r.Header.Set("X-GitLab-Lfs-Tmp", filepath.Base(file.Name()))

	storeReq, err := r.u.newUpstreamRequest(r.Request, nil, "")
	if err != nil {
		fail500(w, fmt.Errorf("handleStoreLfsObject: newUpstreamRequest: %v", err))
		return
	}

	storeResponse, err := r.u.httpClient.Do(storeReq)
	if err != nil {
		fail500(w, fmt.Errorf("handleStoreLfsObject: do %v: %v", storeReq.URL.Path, err))
		return
	}
	defer storeResponse.Body.Close()

	forwardResponseToClient(w, storeResponse)
}
