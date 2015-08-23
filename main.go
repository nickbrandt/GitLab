/*
gitlab-git-http-server handles 'smart' Git HTTP requests for GitLab

This HTTP server can service 'git clone', 'git push' etc. commands
from Git clients that use the 'smart' Git HTTP protocol (git-upload-pack
and git-receive-pack). It is intended to be deployed behind NGINX
(for request routing and SSL termination) with access to a GitLab
backend (for authentication and authorization) and local disk access
to Git repositories managed by GitLab. In GitLab, this role was previously
performed by gitlab-grack.

This file contains the main() function. Actual Git HTTP requests are handled by
the gitHandler type, implemented in githandler.go.
*/
package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"syscall"
)

var Version string // Set at build time in the Makefile

func main() {
	printVersion := flag.Bool("version", false, "Print version and exit")
	listenAddr := flag.String("listenAddr", "localhost:8181", "Listen address for HTTP server")
	listenNetwork := flag.String("listenNetwork", "tcp", "Listen 'network' (tcp, tcp4, tcp6, unix)")
	listenUmask := flag.Int("listenUmask", 022, "Umask for Unix socket, default: 022")
	authBackend := flag.String("authBackend", "http://localhost:8080", "Authentication/authorization backend")
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "\n  %s [OPTIONS] REPO_ROOT\n\nOptions:\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()

	if *printVersion {
		fmt.Printf("gitlab-git-http-server %s\n", Version)
		os.Exit(0)
	}

	repoRoot := flag.Arg(0)
	if repoRoot == "" {
		flag.Usage()
		os.Exit(1)
	}
	log.Printf("repoRoot: %s", repoRoot)

	// Good housekeeping for Unix sockets: unlink before binding
	if *listenNetwork == "unix" {
		if err := os.Remove(*listenAddr); err != nil && !os.IsNotExist(err) {
			log.Fatal(err)
		}
	}

	// Change the umask only around net.Listen()
	oldUmask := syscall.Umask(*listenUmask)
	listener, err := net.Listen(*listenNetwork, *listenAddr)
	syscall.Umask(oldUmask)
	if err != nil {
		log.Fatal(err)
	}

	http.Handle("/", newGitHandler(repoRoot, *authBackend))
	log.Fatal(http.Serve(listener, nil))
}
