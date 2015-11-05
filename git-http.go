/*
In this file we handle the Git 'smart HTTP' protocol
*/

package main

import (
	"compress/gzip"
	"fmt"
	"io"
	"net/http"
	"strings"
)

func handleGetInfoRefs(w http.ResponseWriter, r *gitRequest, _ string) {
	rpc := r.URL.Query().Get("service")
	if !(rpc == "git-upload-pack" || rpc == "git-receive-pack") {
		// The 'dumb' Git HTTP protocol is not supported
		http.Error(w, "Not Found", 404)
		return
	}

	// Prepare our Git subprocess
	cmd := gitCommand(r.GL_ID, "git", subCommand(rpc), "--stateless-rpc", "--advertise-refs", r.RepoPath)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fail500(w, "handleGetInfoRefs", err)
		return
	}
	defer stdout.Close()
	if err := cmd.Start(); err != nil {
		fail500(w, "handleGetInfoRefs", err)
		return
	}
	defer cleanUpProcessGroup(cmd) // Ensure brute force subprocess clean-up

	// Start writing the response
	w.Header().Add("Content-Type", fmt.Sprintf("application/x-%s-advertisement", rpc))
	w.Header().Add("Cache-Control", "no-cache")
	w.WriteHeader(200) // Don't bother with HTTP 500 from this point on, just return
	if err := pktLine(w, fmt.Sprintf("# service=%s\n", rpc)); err != nil {
		logContext("handleGetInfoRefs response", err)
		return
	}
	if err := pktFlush(w); err != nil {
		logContext("handleGetInfoRefs response", err)
		return
	}
	if _, err := io.Copy(w, stdout); err != nil {
		logContext("handleGetInfoRefs read from subprocess", err)
		return
	}
	if err := cmd.Wait(); err != nil {
		logContext("handleGetInfoRefs wait for subprocess", err)
		return
	}

	return
}

func handlePostRPC(w http.ResponseWriter, r *gitRequest, rpc string) {
	var body io.ReadCloser
	var err error

	// The client request body may have been gzipped.
	if r.Header.Get("Content-Encoding") == "gzip" {
		body, err = gzip.NewReader(r.Body)
		if err != nil {
			fail500(w, "handlePostRPC", err)
			return
		}
	} else {
		body = r.Body
	}
	defer body.Close()

	// Prepare our Git subprocess
	cmd := gitCommand(r.GL_ID, "git", subCommand(rpc), "--stateless-rpc", r.RepoPath)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fail500(w, "handlePostRPC", err)
		return
	}
	defer stdout.Close()
	stdin, err := cmd.StdinPipe()
	if err != nil {
		fail500(w, "handlePostRPC", err)
		return
	}
	defer stdin.Close()
	if err := cmd.Start(); err != nil {
		fail500(w, "handlePostRPC", err)
		return
	}
	defer cleanUpProcessGroup(cmd) // Ensure brute force subprocess clean-up

	// Write the client request body to Git's standard input
	if _, err := io.Copy(stdin, body); err != nil {
		fail500(w, "handlePostRPC write to subprocess", err)
		return
	}
	// Signal to the Git subprocess that no more data is coming
	stdin.Close()

	// It may take a while before we return and the deferred closes happen
	// so let's free up some resources already.
	r.Body.Close()
	// If the body was compressed, body != r.Body and this frees up the
	// gzip.Reader.
	body.Close()

	// Start writing the response
	w.Header().Add("Content-Type", fmt.Sprintf("application/x-%s-result", rpc))
	w.Header().Add("Cache-Control", "no-cache")
	w.WriteHeader(200) // Don't bother with HTTP 500 from this point on, just return

	// This io.Copy may take a long time, both for Git push and pull.
	if _, err := io.Copy(w, stdout); err != nil {
		logContext("handlePostRPC read from subprocess", err)
		return
	}
	if err := cmd.Wait(); err != nil {
		logContext("handlePostRPC wait for subprocess", err)
		return
	}

	return
}

func subCommand(rpc string) string {
	return strings.TrimPrefix(rpc, "git-")
}

func pktLine(w io.Writer, s string) error {
	_, err := fmt.Fprintf(w, "%04x%s", len(s)+4, s)
	return err
}

func pktFlush(w io.Writer) error {
	_, err := fmt.Fprint(w, "0000")
	return err
}
