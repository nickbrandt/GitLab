package parser

import (
	"bytes"
	"encoding/json"
	"html/template"
	"io"
	"strings"

	"github.com/alecthomas/chroma"
	"github.com/alecthomas/chroma/lexers"
)

var (
	languageTemplate = template.Must(template.New("lang").Parse(`<span class="line" lang="{{.}}">`))
	valueTemplate    = template.Must(template.New("value").Parse(`<span class="{{.Class}}">{{.Value}}</span>`))
)

type CodeHover struct {
	Value    string `json:"value"`
	Language string `json:"language,omitempty"`
}

func NewCodeHover(content json.RawMessage) (*CodeHover, error) {
	// Hover value can be either an object: { "value": "func main()", "language": "go" }
	// Or a string with documentation
	// We try to unmarshal the content into a string and if we fail, we unmarshal it into an object
	var codeHover CodeHover
	if err := json.Unmarshal(content, &codeHover.Value); err != nil {
		if err := json.Unmarshal(content, &codeHover); err != nil {
			return nil, err
		}

		codeHover.Highlight()
	}

	return &codeHover, nil
}

func (c *CodeHover) Highlight() {
	var b bytes.Buffer

	for i, line := range c.codeLines() {
		if i > 0 {
			if _, err := io.WriteString(&b, "\n"); err != nil {
				return
			}
		}

		languageTemplate.Execute(&b, c.Language)

		for _, token := range line {
			if err := writeTokenValue(&b, token); err != nil {
				return
			}
		}

		if _, err := io.WriteString(&b, "</span>"); err != nil {
			return
		}
	}

	c.Value = b.String()
}

func writeTokenValue(w io.Writer, token chroma.Token) error {
	if strings.HasPrefix(token.Type.String(), "Keyword") || token.Type == chroma.String || token.Type == chroma.Comment {
		data := struct {
			Class string
			Value string
		}{
			Class: chroma.StandardTypes[token.Type],
			Value: replaceNewLines(token.Value),
		}
		return valueTemplate.Execute(w, data)
	}

	_, err := io.WriteString(w, template.HTMLEscapeString(replaceNewLines(token.Value)))
	return err
}

func replaceNewLines(value string) string {
	return strings.ReplaceAll(value, "\n", "")
}

func (c *CodeHover) codeLines() [][]chroma.Token {
	lexer := lexers.Get(c.Language)
	if lexer == nil {
		return [][]chroma.Token{}
	}

	iterator, err := lexer.Tokenise(nil, c.Value)
	if err != nil {
		return [][]chroma.Token{}
	}

	return chroma.SplitTokensIntoLines(iterator.Tokens())
}
