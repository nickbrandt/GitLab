package artifacts

import (
	"../api"
	"../helper"
	"../zipartifacts"
	"bufio"
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

func detectFileContentType(fileName string) string {
	contentType := mime.TypeByExtension(filepath.Ext(fileName))
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	return contentType
}

func unpackFileFromZip(archiveFileName, encodedFilename string, headers http.Header, output io.Writer) error {
	fileName, err := zipartifacts.DecodeFileEntry(encodedFilename)
	if err != nil {
		return err
	}

	catFile := exec.Command("gitlab-zip-cat", archiveFileName, encodedFilename)
	catFile.Stderr = os.Stderr
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
		if catFileErr := waitCatFile(catFile); catFileErr != nil {
			return catFileErr
		}
		return fmt.Errorf("read content-length: %v", err)
	}
	contentLength = strings.TrimSuffix(contentLength, "\n")

	// Write http headers about the file
	headers.Set("Content-Length", contentLength)
	headers.Set("Content-Type", detectFileContentType(fileName))
	headers.Set("Content-Disposition", "attachment; filename=\""+escapeQuotes(basename)+"\"")
	// Copy file body to client
	if _, err := io.Copy(output, reader); err != nil {
		return fmt.Errorf("copy %v stdout: %v", catFile.Args, err)
	}

	return waitCatFile(catFile)
}

func waitCatFile(cmd *exec.Cmd) error {
	err := cmd.Wait()
	if err == nil {
		return nil
	}

	if st, ok := helper.ExitStatus(err); ok && st == zipartifacts.StatusEntryNotFound {
		return os.ErrNotExist
	}
	return fmt.Errorf("wait for %v to finish: %v", cmd.Args, err)

}

// Artifacts downloader doesn't support ranges when downloading a single file
func DownloadArtifact(myAPI *api.API) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		if a.Archive == "" || a.Entry == "" {
			helper.Fail500(w, errors.New("DownloadArtifact: Archive or Path is empty"))
			return
		}

		err := unpackFileFromZip(a.Archive, a.Entry, w.Header(), w)
		if os.IsNotExist(err) {
			http.NotFound(w, r)
			return
		} else if err != nil {
			helper.Fail500(w, fmt.Errorf("DownloadArtifact: %v", err))
		}
	}, "")
}
