package zipartifacts

import (
	"archive/zip"
	"compress/gzip"
	"encoding/binary"
	"encoding/json"
	"io"
	"os"
	"strconv"
	"strings"
	"time"
)

type metadata struct {
	Modified int64  `json:"modified"`
	Mode     string `json:"mode"`
	CRC      uint32 `json:"crc,omitempty"`
	Size     uint64 `json:"size,omitempty"`
	Zipped   uint64 `json:"zipped,omitempty"`
	Comment  string `json:"comment,omitempty"`
}

const MetadataHeaderPrefix = "\x00\x00\x00&" // length of string below, encoded properly
const MetadataHeader = "GitLab Build Artifacts Metadata 0.0.2\n"

func newMetadata(file *zip.File) metadata {
	return metadata{
		Modified: file.ModTime().Unix(),
		Mode:     strconv.FormatUint(uint64(file.Mode().Perm()), 8),
		CRC:      file.CRC32,
		Size:     file.UncompressedSize64,
		Zipped:   file.CompressedSize64,
		Comment:  file.Comment,
	}
}

func (m metadata) writeEncoded(output io.Writer) error {
	j, err := json.Marshal(m)
	if err != nil {
		return err
	}
	j = append(j, byte('\n'))
	return writeBytes(output, j)
}

func writeZipEntryMetadata(output io.Writer, entry *zip.File) error {
	err := writeString(output, entry.Name)
	if err != nil {
		return err
	}

	err = newMetadata(entry).writeEncoded(output)
	if err != nil {
		return err
	}
	return nil
}

func handleZipEntryMetadata(output io.Writer, entry *zip.File, entries []*zip.File) error {
	var dirNodes []string

	var calculateEntryNodes func(string)
	calculateEntryNodes = func(str string) {
		idx := strings.LastIndex(str, "/")
		if idx < 0 {
			return
		}
		dir := str[:idx]
		dirNodes = append([]string{dir + "/"}, dirNodes...)
		calculateEntryNodes(dir)
	}
	calculateEntryNodes(entry.Name)

	for _, d := range dirNodes {
		if !hasZipPathEntry(d, entries) {
			var missingHeader zip.FileHeader
			missingHeader.Name = d
			missingHeader.SetModTime(time.Now())
			missingHeader.SetMode(os.FileMode(uint32(0755)))
			missingEntry := &zip.File{FileHeader: missingHeader}

			writeZipEntryMetadata(output, missingEntry)
		}
	}

	err := writeZipEntryMetadata(output, entry)
	return err
}

func hasZipPathEntry(path string, entries []*zip.File) bool {
	for _, e := range entries {
		if e.Name == path {
			return true
		}
	}

	return false
}

func generateZipMetadata(output io.Writer, archive *zip.Reader) error {
	if err := writeString(output, MetadataHeader); err != nil {
		return err
	}

	// Write empty error string
	if err := writeString(output, "{}"); err != nil {
		return err
	}

	// Write all files
	for _, entry := range archive.File {
		if err := handleZipEntryMetadata(output, entry, archive.File); err != nil {
			return err
		}
	}
	return nil
}

func GenerateZipMetadataFromFile(fileName string, w io.Writer) error {
	archive, err := zip.OpenReader(fileName)
	if err != nil {
		// Ignore non-zip archives
		return os.ErrInvalid
	}
	defer archive.Close()

	gz := gzip.NewWriter(w)
	defer gz.Close()

	return generateZipMetadata(gz, &archive.Reader)
}

func writeBytes(output io.Writer, data []byte) error {
	err := binary.Write(output, binary.BigEndian, uint32(len(data)))
	if err == nil {
		_, err = output.Write(data)
	}
	return err
}

func writeString(output io.Writer, str string) error {
	return writeBytes(output, []byte(str))
}
