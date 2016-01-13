package artifacts

import (
	"mime/multipart"
	"fmt"
	"archive/zip"
	"compress/gzip"
)

type artifactsFormFilter struct {
}

func (a *artifactsFormFilter) FilterFile(formName, fileName string, writer *multipart.Writer) error {
	if formName != "file" {
		return fmt.Errorf("Invalid form field: %q", formName)
	}

	archive, err := zip.OpenReader(fileName)
	if err != nil {
		// Ignore non-zip archives
		return nil
	}
	defer archive.Close()

	// TODO:
	// we could create a temporary file and save to this file instead of writing to mulipart.Writer
	// doing it like this is simpler, but puts more pressure on memory
	metadataFile, err := writer.CreateFormFile("metadata", "metadata.gz")
	if err != nil {
		return err
	}
	defer writer.Close()

	gz := gzip.NewWriter(metadataFile)
	defer gz.Close()

	err = generateZipMetadata(gz, &archive.Reader)
	if err != nil {
		return err
	}

	return nil
}

func (a *artifactsFormFilter) FilterField(formName string, writer *multipart.Writer) error {
	return nil
}
