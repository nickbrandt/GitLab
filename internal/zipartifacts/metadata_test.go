package zipartifacts

import (
	"archive/zip"
	"bytes"
	"encoding/binary"
	"fmt"
	"testing"
)

func TestMissingMetadataEntries(t *testing.T) {
	var zipBuffer, metaBuffer bytes.Buffer

	archive := zip.NewWriter(&zipBuffer)

	firstFile, err := archive.Create("file1")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Fprint(firstFile, "test12")

	secondFile, err := archive.Create("some/file/dir/file2")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Fprint(secondFile, "test125678")

	archive.Close()

	zipReader := bytes.NewReader(zipBuffer.Bytes())
	zipArchiveReader, _ := zip.NewReader(zipReader, int64(binary.Size(zipBuffer.Bytes())))
	err = generateZipMetadata(&metaBuffer, zipArchiveReader)

	paths := []string{"file1", "some/", "some/file/", "some/file/dir", "some/file/dir/file2"}
	for _, path := range paths {
		if !bytes.Contains(metaBuffer.Bytes(), []byte(path)) {
			t.Fatalf("zipartifacts: metadata for path %s not found!", path)
		}
	}
}
