package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/zipartifacts"
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
		fmt.Fprintf(os.Stderr, "Usage: %s FILE.ZIP\n", progName)
		os.Exit(1)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	archive, err := zipartifacts.OpenArchive(ctx, os.Args[1])
	if err != nil {
		fatalError(err)
	}

	if err := zipartifacts.GenerateZipMetadata(os.Stdout, archive); err != nil {
		fatalError(err)
	}
}

func fatalError(err error) {
	fmt.Fprintf(os.Stderr, "%s: %v\n", progName, err)
	if err == zipartifacts.ErrNotAZip {
		os.Exit(zipartifacts.StatusNotZip)
	}
	os.Exit(1)
}
