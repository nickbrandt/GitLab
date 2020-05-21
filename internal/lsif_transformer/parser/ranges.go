package parser

import (
	"encoding/json"
	"io"
	"strconv"
)

const Definitions = "definitions"
const References = "references"

type Ranges struct {
	Entries map[string]*Range
	DefRefs map[string]*DefRef
	Hovers  *Hovers
}

type RawRange struct {
	Id   string `json:"id"`
	Data Range  `json:"start"`
}

type Range struct {
	Line      int `json:"line"`
	Character int `json:"character"`
	RefId     string
}

type RawDefRef struct {
	Property string   `json:"property"`
	RefId    string   `json:"outV"`
	RangeIds []string `json:"inVs"`
	DocId    string   `json:"document"`
}

type DefRef struct {
	Line  string
	DocId string
}

type SerializedRange struct {
	StartLine      int             `json:"start_line"`
	StartChar      int             `json:"start_char"`
	DefinitionPath string          `json:"definition_path,omitempty"`
	Hover          json.RawMessage `json:"hover"`
}

func NewRanges(tempDir string) (*Ranges, error) {
	hovers, err := NewHovers(tempDir)
	if err != nil {
		return nil, err
	}

	return &Ranges{
		Entries: make(map[string]*Range),
		DefRefs: make(map[string]*DefRef),
		Hovers:  hovers,
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

func (r *Ranges) Serialize(f io.Writer, rangeIds []string, docs map[string]string) error {
	encoder := json.NewEncoder(f)
	n := len(rangeIds)

	if _, err := f.Write([]byte("[")); err != nil {
		return err
	}

	for i, rangeId := range rangeIds {
		entry := r.Entries[rangeId]
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
	return r.Hovers.Close()
}

func (r *Ranges) definitionPathFor(docs map[string]string, refId string) string {
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

	r.Entries[rg.Id] = &rg.Data

	return nil
}

func (r *Ranges) addItem(line []byte) error {
	var defRef RawDefRef
	if err := json.Unmarshal(line, &defRef); err != nil {
		return err
	}

	if defRef.Property != Definitions && defRef.Property != References {
		return nil
	}

	for _, rangeId := range defRef.RangeIds {
		if entry, ok := r.Entries[rangeId]; ok {
			entry.RefId = defRef.RefId
		}
	}

	if defRef.Property != Definitions {
		return nil
	}

	defRange := r.Entries[defRef.RangeIds[0]]

	r.DefRefs[defRef.RefId] = &DefRef{
		Line:  strconv.Itoa(defRange.Line + 1),
		DocId: defRef.DocId,
	}

	return nil
}
