package main

import (
	"archive/zip"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
)

const notFound = 2
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

	archiveFileName := os.Args[1]
	fileName := os.Args[2]
	archive, err := zip.OpenReader(archiveFileName)
	if err != nil {
		printError(fmt.Errorf("open %q: %v", archiveFileName, err))
		os.Exit(notFound)
	}
	defer archive.Close()

	file := findFileInZip(fileName, &archive.Reader)
	if file == nil {
		printError(fmt.Errorf("find %q in %q: not found", fileName, archiveFileName))
		os.Exit(notFound)
	}
	// Start decompressing the file
	reader, err := file.Open()
	if err != nil {
		fatalError(fmt.Errorf("open %q in %q: %v", fileName, archiveFileName, err))
	}
	defer reader.Close()
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
	log.Printf("%s: %v", progName, err)
}

func fatalError(err error) {
	printError(err)
	os.Exit(1)
}
