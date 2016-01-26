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

	// non-POSIX paths are here just to test if we never enter infinite loop
	files := []string{"file1", "some/file/dir/", "some/file/dir/file2", "../../test12/test",
		"/usr/bin/test", `c:\windows\win32.exe`, `c:/windows/win.dll`, "./f/asd", "/"}

	for _, file := range files {
		archiveFile, err := archive.Create(file)
		if err != nil {
			t.Fatal(err)
		}
		fmt.Fprint(archiveFile, file)
	}

	archive.Close()

	zipReader := bytes.NewReader(zipBuffer.Bytes())
	zipArchiveReader, _ := zip.NewReader(zipReader, int64(binary.Size(zipBuffer.Bytes())))
	if err := generateZipMetadata(&metaBuffer, zipArchiveReader); err != nil {
		t.Fatal("zipartifacts: generateZipMetadata failed", err)
	}

	paths := []string{"file1", "some/", "some/file/", "some/file/dir/", "some/file/dir/file2"}
	for _, path := range paths {
		if !bytes.Contains(metaBuffer.Bytes(), []byte(path+"\x00")) {
			t.Fatal("zipartifacts: metadata for path", path, "not found")
		}
	}
}
