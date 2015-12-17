/*
In this file we handle git lfs objects downloads and uploads
*/

package main

import (
	"bytes"
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

func (u *upstream) lfsAuthorizeHandler(handleFunc serviceHandleFunc) httpHandleFunc {
	return u.preAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *authorizationResponse) {

		if a.StoreLFSPath == "" {
			fail500(w, errors.New("lfsAuthorizeHandler: StoreLFSPath empty"))
			return
		}

		if a.LfsOid == "" {
			fail500(w, errors.New("lfsAuthorizeHandler: LfsOid empty"))
			return
		}

		if err := os.MkdirAll(a.StoreLFSPath, 0700); err != nil {
			fail500(w, fmt.Errorf("lfsAuthorizeHandler: mkdia StoreLFSPath: %v", err))
			return
		}

		handleFunc(w, r, a)
	}, "/authorize")
}

func (u *upstream) handleStoreLfsObject(w http.ResponseWriter, r *http.Request, a *authorizationResponse) {
	file, err := ioutil.TempFile(a.StoreLFSPath, a.LfsOid)
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

	if written != a.LfsSize {
		fail500(w, fmt.Errorf("handleStoreLfsObject: expected size %d, wrote %d", a.LfsSize, written))
		return
	}

	shaStr := hex.EncodeToString(hash.Sum(nil))
	if shaStr != a.LfsOid {
		fail500(w, fmt.Errorf("handleStoreLfsObject: expected sha256 %s, got %s", a.LfsOid, shaStr))
		return
	}

	// Inject header and body
	r.Header.Set("X-GitLab-Lfs-Tmp", filepath.Base(file.Name()))
	r.Body = ioutil.NopCloser(&bytes.Buffer{})
	r.ContentLength = 0

	// And proxy the request
	u.proxyRequest(w, r)
}
