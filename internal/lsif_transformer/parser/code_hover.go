package parser

import (
	"encoding/json"
	"strings"

	"github.com/alecthomas/chroma"
	"github.com/alecthomas/chroma/lexers"
)

type token struct {
	Class string `json:"class,omitempty"`
	Value string `json:"value"`
}

type codeHover struct {
	Value    string    `json:"value,omitempty"`
	Tokens   [][]token `json:"tokens,omitempty"`
	Language string    `json:"language,omitempty"`
}

func newCodeHover(content json.RawMessage) (*codeHover, error) {
	// Hover value can be either an object: { "value": "func main()", "language": "go" }
	// Or a string with documentation
	// We try to unmarshal the content into a string and if we fail, we unmarshal it into an object
	var c codeHover
	if err := json.Unmarshal(content, &c.Value); err != nil {
		if err := json.Unmarshal(content, &c); err != nil {
			return nil, err
		}

		c.setTokens()
	}

	return &c, nil
}

func (c *codeHover) setTokens() {
	lexer := lexers.Get(c.Language)
	if lexer == nil {
		return
	}

	iterator, err := lexer.Tokenise(nil, c.Value)
	if err != nil {
		return
	}

	var tokenLines [][]token
	for _, tokenLine := range chroma.SplitTokensIntoLines(iterator.Tokens()) {
		var tokens []token
		var rawToken string
		for _, t := range tokenLine {
			class := c.classFor(t.Type)

			// accumulate consequent raw values in a single string to store them as
			// [{ Class: "kd", Value: "func" }, { Value: " main() {" }] instead of
			// [{ Class: "kd", Value: "func" }, { Value: " " }, { Value: "main" }, { Value: "(" }...]
			if class == "" {
				rawToken = rawToken + t.Value
			} else {
				if rawToken != "" {
					tokens = append(tokens, token{Value: rawToken})
					rawToken = ""
				}

				tokens = append(tokens, token{Class: class, Value: t.Value})
			}
		}

		if rawToken != "" {
			tokens = append(tokens, token{Value: rawToken})
		}

		tokenLines = append(tokenLines, tokens)
	}

	c.Tokens = tokenLines
	c.Value = ""
}

func (c *codeHover) classFor(tokenType chroma.TokenType) string {
	if strings.HasPrefix(tokenType.String(), "Keyword") || tokenType == chroma.String || tokenType == chroma.Comment {
		return chroma.StandardTypes[tokenType]
	}

	return ""
}
