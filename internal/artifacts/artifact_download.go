package artifacts

import (
	"../api"
	"../helper"
	"bufio"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"mime"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

const exitStatusNotFound = 2

var notFoundString = fmt.Sprintf("%d", -exitStatusNotFound)

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

func unpackFileFromZip(archiveFileName, fileName string, headers http.Header, output io.Writer) error {
	catFile := exec.Command("gitlab-zip-cat", archiveFileName, fileName)
	catFile.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	stdout, err := catFile.StdoutPipe()
	if err != nil {
		return fmt.Errorf("create gitlab-zip-cat stdout pipe: %v", err)
	}

	if err := catFile.Start(); err != nil {
		return fmt.Errorf("start %v: %v", catFile.Args, err)
	}
	defer helper.CleanUpProcessGroup(catFile)

	basename := filepath.Base(fileName)
	reader := bufio.NewReader(stdout)
	contentLength, err := reader.ReadString('\n')
	if err != nil {
		return fmt.Errorf("read content-length: %v", err)
	}
	contentLength = strings.TrimSuffix(contentLength, "\n")
	if contentLength == notFoundString {
		return os.ErrNotExist
	}

	// Write http headers about the file
	headers.Set("Content-Length", contentLength)
	headers.Set("Content-Type", detectFileContentType(fileName))
	headers.Set("Content-Disposition", "attachment; filename=\""+escapeQuotes(basename)+"\"")
	// Copy file body to client
	if _, err := io.Copy(output, reader); err != nil {
		return fmt.Errorf("copy %v stdout: %v", catFile.Args, err)
	}

	if err := catFile.Wait(); err != nil {
		if st, ok := helper.ExitStatus(err); ok && st == exitStatusNotFound {
			return os.ErrNotExist
		}

		return fmt.Errorf("wait for %v to finish: %v", catFile.Args, err)
	}

	return nil
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
