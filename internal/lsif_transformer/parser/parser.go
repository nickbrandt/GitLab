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

func NewParser(r io.Reader, tempDir string) (*Parser, error) {
	docs, err := NewDocs(tempDir)
	if err != nil {
		return nil, err
	}

	zr, err := openZipReader(r, tempDir)
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
	defer os.Remove(tempFile.Name())

	if _, err := io.Copy(tempFile, reader); err != nil {
		return nil, err
	}

	zr, err := zip.OpenReader(tempFile.Name())
	if err != nil {
		return nil, err
	}

	f := zr.File[0]
	if f == nil {
		return nil, errors.New("invalid zip file")
	}

	return f.Open()
}
