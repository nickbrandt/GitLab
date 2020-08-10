package parser

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestReferencesStore(t *testing.T) {
	const (
		docId = 1
		refId = 3
	)

	r := NewReferences(Config{ProcessReferences: true})

	r.Store(refId, []Item{{Line: 2, DocId: docId}, {Line: 3, DocId: docId}})

	docs := map[Id]string{docId: "doc.go"}
	serializedReferences := r.For(docs, refId)

	require.Contains(t, serializedReferences, SerializedReference{Path: "doc.go#L2"})
	require.Contains(t, serializedReferences, SerializedReference{Path: "doc.go#L3"})
}
