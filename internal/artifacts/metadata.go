package artifacts
import (
	"archive/zip"
	"io"
	"encoding/binary"
	"encoding/json"
)

type metadata struct {
	Modified uint16 `json:"modified"`
	CRC      uint32 `json:"crc,omitempty"`
	Size     uint64 `json:"size,omitempty"`
	Zipped   uint64 `json:"zipped,omitempty"`
	Comment  string `json:"comment,omitempty"`
}

func newMetadata(file *zip.File) metadata {
	return metadata{
		Modified: file.ModifiedDate,
		CRC:      file.CRC32,
		Size:     file.CompressedSize64,
		Zipped:   file.UncompressedSize64,
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
	err := writeString(output, "GitLab Build Artifacts Metadata 0.0.1\n")
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
