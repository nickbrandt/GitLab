package parser

import (
	"encoding/json"
	"io"
	"strconv"
)

const (
	definitions = "definitions"
	references  = "references"
)

type Ranges struct {
	DefRefs map[Id]*DefRef
	Hovers  *Hovers
	Cache   *cache
}

type RawRange struct {
	Id   Id    `json:"id"`
	Data Range `json:"start"`
}

type Range struct {
	Line      int32 `json:"line"`
	Character int32 `json:"character"`
	RefId     Id
}

type RawDefRef struct {
	Property string `json:"property"`
	RefId    Id     `json:"outV"`
	RangeIds []Id   `json:"inVs"`
	DocId    Id     `json:"document"`
}

type DefRef struct {
	Line  string
	DocId Id
}

type SerializedRange struct {
	StartLine      int32           `json:"start_line"`
	StartChar      int32           `json:"start_char"`
	DefinitionPath string          `json:"definition_path,omitempty"`
	Hover          json.RawMessage `json:"hover"`
}

func NewRanges(tempDir string) (*Ranges, error) {
	hovers, err := NewHovers(tempDir)
	if err != nil {
		return nil, err
	}

	cache, err := newCache(tempDir, "ranges", Range{})
	if err != nil {
		return nil, err
	}

	return &Ranges{
		DefRefs: make(map[Id]*DefRef),
		Hovers:  hovers,
		Cache:   cache,
	}, nil
}

func (r *Ranges) Read(label string, line []byte) error {
	switch label {
	case "range":
		if err := r.addRange(line); err != nil {
			return err
		}
	case "item":
		if err := r.addItem(line); err != nil {
			return err
		}
	default:
		return r.Hovers.Read(label, line)
	}

	return nil
}

func (r *Ranges) Serialize(f io.Writer, rangeIds []Id, docs map[Id]string) error {
	encoder := json.NewEncoder(f)
	n := len(rangeIds)

	if _, err := f.Write([]byte("[")); err != nil {
		return err
	}

	for i, rangeId := range rangeIds {
		entry, err := r.getRange(rangeId)
		if err != nil {
			continue
		}

		serializedRange := SerializedRange{
			StartLine:      entry.Line,
			StartChar:      entry.Character,
			DefinitionPath: r.definitionPathFor(docs, entry.RefId),
			Hover:          r.Hovers.For(entry.RefId),
		}
		if err := encoder.Encode(serializedRange); err != nil {
			return err
		}
		if i+1 < n {
			if _, err := f.Write([]byte(",")); err != nil {
				return err
			}
		}
	}

	if _, err := f.Write([]byte("]")); err != nil {
		return err
	}

	return nil
}

func (r *Ranges) Close() error {
	if err := r.Cache.Close(); err != nil {
		return err
	}

	return r.Hovers.Close()
}

func (r *Ranges) definitionPathFor(docs map[Id]string, refId Id) string {
	defRef, ok := r.DefRefs[refId]
	if !ok {
		return ""
	}

	defPath := docs[defRef.DocId] + "#L" + defRef.Line

	return defPath
}

func (r *Ranges) addRange(line []byte) error {
	var rg RawRange
	if err := json.Unmarshal(line, &rg); err != nil {
		return err
	}

	return r.Cache.SetEntry(rg.Id, &rg.Data)
}

func (r *Ranges) addItem(line []byte) error {
	var defRef RawDefRef
	if err := json.Unmarshal(line, &defRef); err != nil {
		return err
	}

	if defRef.Property != definitions && defRef.Property != references {
		return nil
	}

	for _, rangeId := range defRef.RangeIds {
		var rg Range
		if err := r.Cache.Entry(rangeId, &rg); err != nil {
			return err
		}

		rg.RefId = defRef.RefId

		if err := r.Cache.SetEntry(rangeId, &rg); err != nil {
			return err
		}
	}

	if defRef.Property == definitions {
		return r.addDefRef(&defRef)
	}

	return nil
}

func (r *Ranges) addDefRef(defRef *RawDefRef) error {
	var rg Range
	if err := r.Cache.Entry(defRef.RangeIds[0], &rg); err != nil {
		return err
	}

	r.DefRefs[defRef.RefId] = &DefRef{
		Line:  strconv.Itoa(int(rg.Line + 1)),
		DocId: defRef.DocId,
	}

	return nil
}

func (r *Ranges) getRange(rangeId Id) (*Range, error) {
	var rg Range
	if err := r.Cache.Entry(rangeId, &rg); err != nil {
		return nil, err
	}

	return &rg, nil
}
