package main

import (
	"../../internal/zipmetadata"
	"flag"
	"fmt"
	"os"
)

const progName = "gitlab-zip-metadata"

var Version = "unknown"

var printVersion = flag.Bool("version", false, "Print version and exit")

func main() {
	flag.Parse()

	version := fmt.Sprintf("%s %s", progName, Version)
	if *printVersion {
		fmt.Println(version)
		os.Exit(0)
	}

	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s FILE.ZIP", progName)
		os.Exit(1)
	}
	if err := zipmetadata.GenerateZipMetadataFromFile(os.Args[1], os.Stdout); err != nil {
		fmt.Fprintf(os.Stderr, "%s: %v\n", progName, err)
		if err == os.ErrInvalid {
			os.Exit(zipmetadata.StatusNotZip)
		}
		os.Exit(1)
	}
}
