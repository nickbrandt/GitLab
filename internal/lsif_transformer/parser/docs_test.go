package parser

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

func createLine(id, label, uri string) []byte {
	return []byte(fmt.Sprintf(`{"id":"%s","label":"%s","uri":"%s"}`, id, label, uri))
}

func TestRead(t *testing.T) {
	d, err := NewDocs("")
	require.NoError(t, err)
	defer d.Close()

	metadataLine := []byte(`{"id":"1","label":"metaData","projectRoot":"file:///Users/nested"}`)

	require.NoError(t, d.Read(metadataLine))
	require.NoError(t, d.Read(createLine("2", "document", "file:///Users/nested/file.rb")))
	require.NoError(t, d.Read(createLine("3", "document", "file:///Users/nested/folder/file.rb")))
	require.NoError(t, d.Read(createLine("4", "document", "file:///Users/wrong/file.rb")))

	require.Equal(t, d.Entries[2], "file.rb")
	require.Equal(t, d.Entries[3], "folder/file.rb")
	require.Equal(t, d.Entries[4], "file:///Users/wrong/file.rb")
}

func TestReadContainsLine(t *testing.T) {
	d, err := NewDocs("")
	require.NoError(t, err)
	defer d.Close()

	line := []byte(`{"id":"5","label":"contains","outV":"1", "inVs": ["2", "3"]}`)

	require.NoError(t, d.Read(line))

	require.Equal(t, []Id{2, 3}, d.DocRanges[1])
}
