/*
In this file we handle 'git archive' downloads
*/

package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path"
	"time"
	"path/filepath"
	"errors"
)

func handleGetArchive(w http.ResponseWriter, r *gitRequest) {
	var format string
	switch filepath.Base(r.URL.Path) {
	case "archive.zip":
		format = "zip"
	case "archive.tar":
		format = "tar"
	case "archive", "archive.tar.gz":
		format = "tar.gz"
	case "archive.tar.bz2":
		format = "tar.bz2"
	default:
		fail500(w, "handleGetArchive", errors.New("invalid archive format"))
	}

	archiveFilename := path.Base(r.ArchivePath)

	if cachedArchive, err := os.Open(r.ArchivePath); err == nil {
		defer cachedArchive.Close()
		log.Printf("Serving cached file %q", r.ArchivePath)
		setArchiveHeaders(w, format, archiveFilename)
		// Even if somebody deleted the cachedArchive from disk since we opened
		// the file, Unix file semantics guarantee we can still read from the
		// open file in this process.
		http.ServeContent(w, r.Request, "", time.Unix(0, 0), cachedArchive)
		return
	}

	// We assume the tempFile has a unique name so that concurrent requests are
	// safe. We create the tempfile in the same directory as the final cached
	// archive we want to create so that we can use an atomic link(2) operation
	// to finalize the cached archive.
	tempFile, err := prepareArchiveTempfile(path.Dir(r.ArchivePath), archiveFilename)
	if err != nil {
		fail500(w, "handleGetArchive create tempfile for archive", err)
	}
	defer tempFile.Close()
	defer os.Remove(tempFile.Name())

	compressCmd, archiveFormat := parseArchiveFormat(format)

	archiveCmd := gitCommand("", "git", "--git-dir="+r.RepoPath, "archive", "--format="+archiveFormat, "--prefix="+r.ArchivePrefix+"/", r.CommitId)
	archiveStdout, err := archiveCmd.StdoutPipe()
	if err != nil {
		fail500(w, "handleGetArchive", err)
		return
	}
	defer archiveStdout.Close()
	if err := archiveCmd.Start(); err != nil {
		fail500(w, "handleGetArchive", err)
		return
	}
	defer cleanUpProcessGroup(archiveCmd) // Ensure brute force subprocess clean-up

	var stdout io.ReadCloser
	if compressCmd == nil {
		stdout = archiveStdout
	} else {
		compressCmd.Stdin = archiveStdout

		stdout, err = compressCmd.StdoutPipe()
		if err != nil {
			fail500(w, "handleGetArchive compressCmd stdout pipe", err)
			return
		}
		defer stdout.Close()

		if err := compressCmd.Start(); err != nil {
			fail500(w, "handleGetArchive start compressCmd process", err)
			return
		}
		defer compressCmd.Wait()

		archiveStdout.Close()
	}
	// Every Read() from stdout will be synchronously written to tempFile
	// before it comes out the TeeReader.
	archiveReader := io.TeeReader(stdout, tempFile)

	// Start writing the response
	setArchiveHeaders(w, format, archiveFilename)
	w.WriteHeader(200) // Don't bother with HTTP 500 from this point on, just return
	if _, err := io.Copy(w, archiveReader); err != nil {
		logContext("handleGetArchive read from subprocess", err)
		return
	}
	if err := archiveCmd.Wait(); err != nil {
		logContext("handleGetArchive wait for archiveCmd", err)
		return
	}
	if compressCmd != nil {
		if err := compressCmd.Wait(); err != nil {
			logContext("handleGetArchive wait for compressCmd", err)
			return
		}
	}

	if err := finalizeCachedArchive(tempFile, r.ArchivePath); err != nil {
		logContext("handleGetArchive finalize cached archive", err)
		return
	}

	return
}

func setArchiveHeaders(w http.ResponseWriter, format string, archiveFilename string) {
	w.Header().Add("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, archiveFilename))
	if format == "zip" {
		w.Header().Add("Content-Type", "application/zip")
	} else {
		w.Header().Add("Content-Type", "application/octet-stream")
	}
	w.Header().Add("Content-Transfer-Encoding", "binary")
	w.Header().Add("Cache-Control", "private")
}

func parseArchiveFormat(format string) (*exec.Cmd, string) {
	switch format {
	case "tar":
		return nil, "tar"
	case "tar.gz":
		return exec.Command("gzip", "-c", "-n"), "tar"
	case "tar.bz2":
		return exec.Command("bzip2", "-c"), "tar"
	case "zip":
		return nil, "zip"
	}
	return nil, "unknown"
}

func prepareArchiveTempfile(dir string, prefix string) (*os.File, error) {
	if err := os.MkdirAll(dir, 0700); err != nil {
		return nil, err
	}
	return ioutil.TempFile(dir, prefix)
}

func finalizeCachedArchive(tempFile *os.File, archivePath string) error {
	if err := tempFile.Close(); err != nil {
		return err
	}
	return os.Link(tempFile.Name(), archivePath)
}
