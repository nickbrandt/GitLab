package main

import (
	"archive/zip"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/jfbus/httprs"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/zipartifacts"
)

const progName = "gitlab-zip-cat"

var Version = "unknown"

var printVersion = flag.Bool("version", false, "Print version and exit")

var httpClient = &http.Client{
	Transport: &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout:   30 * time.Second,
			KeepAlive: 10 * time.Second,
		}).DialContext,
		IdleConnTimeout:       30 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 10 * time.Second,
		ResponseHeaderTimeout: 30 * time.Second,
	},
}

func isURL(path string) bool {
	return strings.HasPrefix(path, "http://") || strings.HasPrefix(path, "https://")
}

func openHTTPArchive(archivePath string) (*zip.Reader, func()) {
	scrubbedArchivePath := helper.ScrubURLParams(archivePath)
	resp, err := httpClient.Get(archivePath)
	if err != nil {
		fatalError(fmt.Errorf("HTTP GET %q: %v", scrubbedArchivePath, err))
	} else if resp.StatusCode == http.StatusNotFound {
		notFoundError(fmt.Errorf("HTTP GET %q: not found", scrubbedArchivePath))
	} else if resp.StatusCode != http.StatusOK {
		fatalError(fmt.Errorf("HTTP GET %q: %d: %v", scrubbedArchivePath, resp.StatusCode, resp.Status))
	}

	rs := httprs.NewHttpReadSeeker(resp, httpClient)

	archive, err := zip.NewReader(rs, resp.ContentLength)
	if err != nil {
		notFoundError(fmt.Errorf("open %q: %v", scrubbedArchivePath, err))
	}

	return archive, func() {
		resp.Body.Close()
		rs.Close()
	}
}

func openFileArchive(archivePath string) (*zip.Reader, func()) {
	archive, err := zip.OpenReader(archivePath)
	if err != nil {
		notFoundError(fmt.Errorf("open %q: %v", archivePath, err))
	}

	return &archive.Reader, func() {
		archive.Close()
	}
}

func openArchive(archivePath string) (*zip.Reader, func()) {
	if isURL(archivePath) {
		return openHTTPArchive(archivePath)
	}

	return openFileArchive(archivePath)
}

func main() {
	flag.Parse()

	version := fmt.Sprintf("%s %s", progName, Version)
	if *printVersion {
		fmt.Println(version)
		os.Exit(0)
	}

	archivePath := os.Getenv("ARCHIVE_PATH")
	encodedFileName := os.Getenv("ENCODED_FILE_NAME")

	if len(os.Args) != 1 || archivePath == "" || encodedFileName == "" {
		fmt.Fprintf(os.Stderr, "Usage: %s\n", progName)
		fmt.Fprintf(os.Stderr, "Env: ARCHIVE_PATH=https://path.to/archive.zip or /path/to/archive.zip\n")
		fmt.Fprintf(os.Stderr, "Env: ENCODED_FILE_NAME=base64-encoded-file-name\n")
		os.Exit(1)
	}

	scrubbedArchivePath := helper.ScrubURLParams(archivePath)

	fileName, err := zipartifacts.DecodeFileEntry(encodedFileName)
	if err != nil {
		fatalError(fmt.Errorf("decode entry %q: %v", encodedFileName, err))
	}

	archive, cleanFn := openArchive(archivePath)
	defer cleanFn()

	file := findFileInZip(fileName, archive)
	if file == nil {
		notFoundError(fmt.Errorf("find %q in %q: not found", fileName, scrubbedArchivePath))
	}
	// Start decompressing the file
	reader, err := file.Open()
	if err != nil {
		fatalError(fmt.Errorf("open %q in %q: %v", fileName, scrubbedArchivePath, err))
	}
	defer reader.Close()

	if _, err := fmt.Printf("%d\n", file.UncompressedSize64); err != nil {
		fatalError(fmt.Errorf("write file size: %v", err))
	}

	if _, err := io.Copy(os.Stdout, reader); err != nil {
		fatalError(fmt.Errorf("write %q from %q to stdout: %v", fileName, scrubbedArchivePath, err))
	}
}

func findFileInZip(fileName string, archive *zip.Reader) *zip.File {
	for _, file := range archive.File {
		if file.Name == fileName {
			return file
		}
	}
	return nil
}

func printError(err error) {
	fmt.Fprintf(os.Stderr, "%s: %v", progName, err)
}

func fatalError(err error) {
	printError(err)
	os.Exit(1)
}

func notFoundError(err error) {
	printError(err)
	os.Exit(zipartifacts.StatusEntryNotFound)
}
