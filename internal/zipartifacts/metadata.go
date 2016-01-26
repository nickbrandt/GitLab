package zipartifacts

import (
	"archive/zip"
	"compress/gzip"
	"encoding/binary"
	"encoding/json"
	"io"
	"os"
	"path"
	"sort"
	"strconv"
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
	if err := writeString(output, entry.Name); err != nil {
		return err
	}

	if err := newMetadata(entry).writeEncoded(output); err != nil {
		return err
	}

	return nil
}

func generateZipMetadata(output io.Writer, archive *zip.Reader) error {
	// Write metadata header
	if err := writeString(output, MetadataHeader); err != nil {
		return err
	}

	// Write empty error header
	if err := writeString(output, "{}"); err != nil {
		return err
	}

	// Create map of files in zip archive
	zipMap := make(map[string]*zip.File, len(archive.File))

	// Add missing entries
	for _, entry := range archive.File {
		zipMap[entry.Name] = entry
		entryPath := entry.Name

		for {
			entryPath = path.Dir(entryPath)
			entryDir := entryPath + "/"
			if entryPath == "." || entryPath == "/" {
				break
			}

			if _, ok := zipMap[entryDir]; !ok {
				var missingHeader zip.FileHeader
				missingHeader.Name = entryDir
				missingHeader.SetModTime(time.Now())
				missingHeader.SetMode(os.FileMode(uint32(0755)))
				missingEntry := &zip.File{FileHeader: missingHeader}

				zipMap[entryDir] = missingEntry
			}
		}
	}

	// Sort paths
	var sortedPaths []string
	for path, _ := range zipMap {
		sortedPaths = append(sortedPaths, path)
	}
	sort.Strings(sortedPaths)

	// Write all files
	for _, path := range sortedPaths {
		if err := writeZipEntryMetadata(output, zipMap[path]); err != nil {
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
