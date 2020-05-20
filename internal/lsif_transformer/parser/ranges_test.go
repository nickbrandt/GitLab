package parser

import (
	"bytes"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestRangesRead(t *testing.T) {
	r, cleanup := setup(t)
	defer cleanup()

	firstRange := Range{Line: 1, Character: 2, RefId: 3}
	require.Equal(t, &firstRange, r.Entries[1])

	secondRange := Range{Line: 5, Character: 4, RefId: 3}
	require.Equal(t, &secondRange, r.Entries[2])
}

func TestSerialize(t *testing.T) {
	r, cleanup := setup(t)
	defer cleanup()

	docs := map[Id]string{6: "def-path"}

	var buf bytes.Buffer
	err := r.Serialize(&buf, []Id{1}, docs)
	want := `[{"start_line":1,"start_char":2,"definition_path":"def-path#L2","hover":null}` + "\n]"

	require.NoError(t, err)
	require.Equal(t, want, buf.String())
}

func setup(t *testing.T) (*Ranges, func()) {
	r, err := NewRanges("")
	require.NoError(t, err)

	require.NoError(t, r.Read("range", []byte(`{"id":1,"label":"range","start":{"line":1,"character":2}}`)))
	require.NoError(t, r.Read("range", []byte(`{"id":"2","label":"range","start":{"line":5,"character":4}}`)))

	require.NoError(t, r.Read("item", []byte(`{"id":4,"label":"item","property":"definitions","outV":"3","inVs":[1],"document":"6"}`)))
	require.NoError(t, r.Read("item", []byte(`{"id":"5","label":"item","property":"references","outV":3,"inVs":["2"]}`)))

	cleanup := func() {
		require.NoError(t, r.Close())
	}

	return r, cleanup
}
