package parser

import (
	"bytes"
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

func createLine(id, label, uri string) []byte {
	return []byte(fmt.Sprintf(`{"id":"%s","label":"%s","uri":"%s"}`+"\n", id, label, uri))
}

func TestParse(t *testing.T) {
	d, err := NewDocs(Config{})
	require.NoError(t, err)
	defer d.Close()

	data := []byte(`{"id":"1","label":"metaData","projectRoot":"file:///Users/nested"}` + "\n")
	data = append(data, createLine("2", "document", "file:///Users/nested/file.rb")...)
	data = append(data, createLine("3", "document", "file:///Users/nested/folder/file.rb")...)
	data = append(data, createLine("4", "document", "file:///Users/wrong/file.rb")...)

	require.NoError(t, d.Parse(bytes.NewReader(data)))

	require.Equal(t, d.Entries[2], "file.rb")
	require.Equal(t, d.Entries[3], "folder/file.rb")
	require.Equal(t, d.Entries[4], "file:///Users/wrong/file.rb")
}

func TestParseContainsLine(t *testing.T) {
	d, err := NewDocs(Config{})
	require.NoError(t, err)
	defer d.Close()

	line := []byte(`{"id":"5","label":"contains","outV":"1", "inVs": ["2", "3"]}` + "\n")

	require.NoError(t, d.Parse(bytes.NewReader(line)))

	require.Equal(t, []Id{2, 3}, d.DocRanges[1])
}
