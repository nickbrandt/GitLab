package main

import (
	"../../internal/zipartifacts"
	"archive/zip"
	"flag"
	"fmt"
	"io"
	"os"
)

const progName = "gitlab-zip-cat"

var Version = "unknown"

var printVersion = flag.Bool("version", false, "Print version and exit")

func main() {
	flag.Parse()

	version := fmt.Sprintf("%s %s", progName, Version)
	if *printVersion {
		fmt.Println(version)
		os.Exit(0)
	}

	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s FILE.ZIP ENTRY\n", progName)
		os.Exit(1)
	}

	archiveFileName := os.Args[1]

	fileName, err := zipartifacts.DecodeFileEntry(os.Args[2])
	if err != nil {
		fatalError(fmt.Errorf("decode entry %q: %v", os.Args[2], err))
	}

	archive, err := zip.OpenReader(archiveFileName)
	if err != nil {
		notFoundError(fmt.Errorf("open %q: %v", archiveFileName, err))
	}
	defer archive.Close()

	file := findFileInZip(fileName, &archive.Reader)
	if file == nil {
		notFoundError(fmt.Errorf("find %q in %q: not found", fileName, archiveFileName))
	}
	// Start decompressing the file
	reader, err := file.Open()
	if err != nil {
		fatalError(fmt.Errorf("open %q in %q: %v", fileName, archiveFileName, err))
	}
	defer reader.Close()

	if _, err := fmt.Printf("%d\n", file.UncompressedSize64); err != nil {
		fatalError(fmt.Errorf("write file size: %v", err))
	}

	if _, err := io.Copy(os.Stdout, reader); err != nil {
		fatalError(fmt.Errorf("write %q from %q to stdout: %v", fileName, archiveFileName, err))
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
