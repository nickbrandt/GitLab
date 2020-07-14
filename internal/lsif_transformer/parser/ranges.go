package parser

import (
	"encoding/json"
	"errors"
	"io"
	"strconv"
)

const (
	definitions = "definitions"
	references  = "references"
)

type Ranges struct {
	DefRefs map[Id]Item
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

type RawItem struct {
	Property string `json:"property"`
	RefId    Id     `json:"outV"`
	RangeIds []Id   `json:"inVs"`
	DocId    Id     `json:"document"`
}

type Item struct {
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
		DefRefs: make(map[Id]Item),
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
	return combineErrors(
		r.Cache.Close(),
		r.Hovers.Close(),
	)
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
	var rawItem RawItem
	if err := json.Unmarshal(line, &rawItem); err != nil {
		return err
	}

	if rawItem.Property != definitions && rawItem.Property != references {
		return nil
	}

	for _, rangeId := range rawItem.RangeIds {
		rg, err := r.getRange(rangeId)
		if err != nil {
			return err
		}

		rg.RefId = rawItem.RefId

		if err := r.Cache.SetEntry(rangeId, rg); err != nil {
			return err
		}
	}

	if rawItem.Property == definitions {
		return r.addDefRef(&rawItem)
	}

	return nil
}

func (r *Ranges) addDefRef(rawItem *RawItem) error {
	if len(rawItem.RangeIds) == 0 {
		return errors.New("no range IDs")
	}

	rg, err := r.getRange(rawItem.RangeIds[0])
	if err != nil {
		return err
	}

	r.DefRefs[rawItem.RefId] = Item{
		Line:  strconv.Itoa(int(rg.Line + 1)),
		DocId: rawItem.DocId,
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
