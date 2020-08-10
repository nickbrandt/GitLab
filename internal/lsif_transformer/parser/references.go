package parser

import (
	"strconv"
)

type References struct {
	Items             map[Id][]Item
	ProcessReferences bool
}

type SerializedReference struct {
	Path string `json:"path"`
}

func NewReferences(config Config) *References {
	return &References{
		Items:             make(map[Id][]Item),
		ProcessReferences: config.ProcessReferences,
	}
}

func (r *References) Store(refId Id, references []Item) {
	if r.ProcessReferences {
		r.Items[refId] = references
	}
}

func (r *References) For(docs map[Id]string, refId Id) []SerializedReference {
	if !r.ProcessReferences {
		return nil
	}

	references, ok := r.Items[refId]
	if !ok {
		return nil
	}

	var serializedReferences []SerializedReference

	for _, reference := range references {
		serializedReference := SerializedReference{
			Path: docs[reference.DocId] + "#L" + strconv.Itoa(int(reference.Line)),
		}

		serializedReferences = append(serializedReferences, serializedReference)
	}

	return serializedReferences
}
