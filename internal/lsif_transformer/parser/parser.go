package parser

import (
	"archive/zip"
	"bufio"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
)

var (
	Lsif = "lsif"
)

type Parser struct {
	Docs *Docs

	pr *io.PipeReader
}

type Config struct {
	TempPath string
}

func NewParser(r io.Reader, config Config) (io.ReadCloser, error) {
	docs, err := NewDocs(config)
	if err != nil {
		return nil, err
	}

	zr, err := openZipReader(r, config.TempPath)
	if err != nil {
		return nil, err
	}
	reader := bufio.NewReader(zr)

	for {
		line, err := reader.ReadBytes('\n')
		if err != nil {
			break
		}

		if err := docs.Read(line); err != nil {
			return nil, err
		}
	}

	pr, pw := io.Pipe()
	parser := &Parser{
		Docs: docs,
		pr:   pr,
	}

	go parser.parse(pw)

	return parser, nil
}

func (p *Parser) Read(b []byte) (int, error) {
	return p.pr.Read(b)
}

func (p *Parser) Close() error {
	p.pr.Close()

	return p.Docs.Close()
}

func (p *Parser) parse(pw *io.PipeWriter) {
	zw := zip.NewWriter(pw)

	if err := p.Docs.SerializeEntries(zw); err != nil {
		zw.Close() // Free underlying resources only
		pw.CloseWithError(fmt.Errorf("lsif parser: Docs.SerializeEntries: %v", err))
		return
	}

	if err := zw.Close(); err != nil {
		pw.CloseWithError(fmt.Errorf("lsif parser: ZipWriter.Close: %v", err))
		return
	}

	pw.Close()
}

func openZipReader(reader io.Reader, tempDir string) (io.Reader, error) {
	tempFile, err := ioutil.TempFile(tempDir, Lsif)
	if err != nil {
		return nil, err
	}

	if err := os.Remove(tempFile.Name()); err != nil {
		return nil, err
	}

	size, err := io.Copy(tempFile, reader)
	if err != nil {
		return nil, err
	}

	if _, err := tempFile.Seek(0, io.SeekStart); err != nil {
		return nil, err
	}

	zr, err := zip.NewReader(tempFile, size)
	if err != nil {
		return nil, err
	}

	if len(zr.File) == 0 {
		return nil, errors.New("empty zip file")
	}

	return zr.File[0].Open()
}
