package artifacts

import (
	"archive/zip"
	"encoding/binary"
	"encoding/json"
	"io"
	"strconv"
)

type metadata struct {
	Modified int64  `json:"modified"`
	Mode     string `json:"mode"`
	CRC      uint32 `json:"crc,omitempty"`
	Size     uint64 `json:"size,omitempty"`
	Zipped   uint64 `json:"zipped,omitempty"`
	Comment  string `json:"comment,omitempty"`
}

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

func (m metadata) write(output io.Writer) error {
	j, err := json.Marshal(m)
	if err != nil {
		return err
	}
	j = append(j, byte('\n'))
	return writeBytes(output, j)
}

func generateZipMetadata(output io.Writer, archive *zip.Reader) error {
	err := writeString(output, "GitLab Build Artifacts Metadata 0.0.2\n")
	if err != nil {
		return err
	}
	err = writeString(output, "{}")
	if err != nil {
		return err
	}

	for _, entry := range archive.File {
		err = writeString(output, entry.Name)
		if err != nil {
			return err
		}

		err = newMetadata(entry).write(output)
		if err != nil {
			return err
		}
	}
	return nil
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
