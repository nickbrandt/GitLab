package artifacts

import (
	"../api"
	"../helper"
	"archive/zip"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
)

func decodeFileEntry(entry string) (string, error) {
	decoded, err := base64.StdEncoding.DecodeString(entry)
	if err != nil {
		return "", err
	}
	return string(decoded), nil
}

func detectFileContentType(fileName string) string {
	contentType := mime.TypeByExtension(filepath.Ext(fileName))
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	return contentType
}

func findFileInZip(fileName string, archive *zip.Reader) *zip.File {
	for _, file := range archive.File {
		if file.Name == fileName {
			return file
		}
	}
	return nil
}

func unpackFileFromZip(archiveFileName, fileName string, headers http.Header, output io.Writer) error {
	archive, err := zip.OpenReader(archiveFileName)
	if err != nil {
		return err
	}
	defer archive.Close()

	file := findFileInZip(fileName, &archive.Reader)
	if file == nil {
		return os.ErrNotExist
	}

	// Start decompressing the file
	reader, err := file.Open()
	if err != nil {
		return err
	}
	defer reader.Close()

	basename := filepath.Base(fileName)

	// Write http headers about the file
	headers.Set("Content-Length", strconv.FormatInt(int64(file.UncompressedSize64), 10))
	headers.Set("Content-Type", detectFileContentType(file.Name))
	headers.Set("Content-Disposition", "attachment; filename=\""+escapeQuotes(basename)+"\"")

	// Copy file body to client
	_, err = io.Copy(output, reader)
	return err
}

// Artifacts downloader doesn't support ranges when downloading a single file
func DownloadArtifact(myAPI *api.API) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		if a.Archive == "" || a.Entry == "" {
			helper.Fail500(w, errors.New("DownloadArtifact: Archive or Path is empty"))
			return
		}

		fileName, err := decodeFileEntry(a.Entry)
		if err != nil {
			helper.Fail500(w, err)
			return
		}

		err = unpackFileFromZip(a.Archive, fileName, w.Header(), w)
		if os.IsNotExist(err) {
			http.NotFound(w, r)
			return
		} else if err != nil {
			helper.Fail500(w, fmt.Errorf("DownloadArtifact: %v", err))
		}
	}, "")
}
