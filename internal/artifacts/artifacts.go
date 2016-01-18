package artifacts

import (
	"../api"
	"../helper"
	"../upload"
	"archive/zip"
	"encoding/base64"
	"errors"
	"io"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
)

func UploadArtifacts(myAPI *api.API, h http.Handler) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		if a.TempPath == "" {
			helper.Fail500(w, errors.New("UploadArtifacts: TempPath is empty"))
			return
		}

		upload.HandleFileUploads(w, r, h, a.TempPath, &artifactsFormFilter{})
	}, "/authorize")
}

// Artifacts downloader doesn't support ranges when downloading a single file
func DownloadArtifact(myAPI *api.API) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		if a.Archive == "" || a.Entry == "" {
			helper.Fail500(w, errors.New("DownloadArtifact: Archive or Path is empty"))
			return
		}

		fileNameDecoded, err := base64.StdEncoding.DecodeString(a.Entry)
		if err != nil {
			helper.Fail500(w, err)
			return
		}
		fileName := string(fileNameDecoded)

		// TODO:
		// This should be moved to sub process to reduce memory pressue on workhorse
		archive, err := zip.OpenReader(a.Archive)
		if os.IsNotExist(err) {
			http.NotFound(w, r)
			return
		} else if err != nil {
			helper.Fail500(w, err)
		}
		defer archive.Close()

		var file *zip.File
		for _, file = range archive.File {
			if file.Name == fileName {
				break
			}
		}
		if file == nil {
			http.NotFound(w, r)
			return
		}

		contentType := mime.TypeByExtension(filepath.Ext(file.Name))
		if contentType == "" {
			contentType = "application/octet-stream"
		}

		w.Header().Set("Content-Length", strconv.FormatInt(int64(file.UncompressedSize64), 10))
		w.Header().Set("Content-Type", contentType)
		w.Header().Set("Content-Disposition", "attachment; filename=\""+filepath.Base(file.Name)+"\"")

		reader, err := file.Open()
		if err != nil {
			helper.Fail500(w, err)
		}
		defer reader.Close()

		// Copy file body
		io.Copy(w, reader)
	}, "")
}
