package parser

import (
	"archive/zip"
	"bufio"
	"bytes"
	"errors"
	"io"
	"io/ioutil"
	"os"
)

var (
	Lsif = "lsif"
)

type Parser struct {
	Docs *Docs
}

type Config struct {
	TempPath string
}

func NewParser(r io.Reader, config Config) (*Parser, error) {
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

	return &Parser{Docs: docs}, nil
}

func (p *Parser) ZipReader() (io.Reader, error) {
	buf := new(bytes.Buffer)
	w := zip.NewWriter(buf)

	if err := p.Docs.SerializeEntries(w); err != nil {
		return nil, err
	}

	if err := w.Close(); err != nil {
		return nil, err
	}

	return buf, nil
}

func (p *Parser) Close() error {
	return p.Docs.Close()
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
