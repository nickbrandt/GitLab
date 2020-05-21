package parser

import (
	"encoding/json"
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestHighlight(t *testing.T) {
	tests := []struct {
		name     string
		language string
		value    string
		want     string
	}{
		{
			name:     "go function definition",
			language: "go",
			value:    "func main()",
			want:     "<span class=\"line\" lang=\"go\"><span class=\"kd\">func</span> main()</span>",
		},
		{
			name:     "go struct definition",
			language: "go",
			value:    "type Command struct",
			want:     "<span class=\"line\" lang=\"go\"><span class=\"kd\">type</span> Command <span class=\"kd\">struct</span></span>",
		},
		{
			name:     "go struct multiline definition",
			language: "go",
			value:    `struct {\nConfig *Config\nReadWriter *ReadWriter\nEOFSent bool\n}`,
			want:     "<span class=\"line\" lang=\"go\"><span class=\"kd\">struct</span> {</span>\n<span class=\"line\" lang=\"go\">Config *Config</span>\n<span class=\"line\" lang=\"go\">ReadWriter *ReadWriter</span>\n<span class=\"line\" lang=\"go\">EOFSent <span class=\"kt\">bool</span></span>\n<span class=\"line\" lang=\"go\">}</span>",
		},
		{
			name:     "ruby method definition",
			language: "ruby",
			value:    "def read(line)",
			want:     "<span class=\"line\" lang=\"ruby\"><span class=\"k\">def</span> read(line)</span>",
		},
		{
			name:     "amp symbol is escaped",
			language: "ruby",
			value:    `def &(line)\nend`,
			want:     "<span class=\"line\" lang=\"ruby\"><span class=\"k\">def</span> &amp;(line)</span>\n<span class=\"line\" lang=\"ruby\"><span class=\"k\">end</span></span>",
		},
		{
			name:     "less symbol is escaped",
			language: "ruby",
			value:    "def <(line)",
			want:     "<span class=\"line\" lang=\"ruby\"><span class=\"k\">def</span> &lt;(line)</span>",
		},
		{
			name:     "more symbol is escaped",
			language: "ruby",
			value:    `def >(line)\nend`,
			want:     "<span class=\"line\" lang=\"ruby\"><span class=\"k\">def</span> &gt;(line)</span>\n<span class=\"line\" lang=\"ruby\"><span class=\"k\">end</span></span>",
		},
		{
			name:     "unknown/malicious language is passed",
			language: "<lang> alert(1); </lang>",
			value:    `def a;\nend`,
			want:     "",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			raw := []byte(fmt.Sprintf(`{"language":"%s","value":"%s"}`, tt.language, tt.value))
			c, err := NewCodeHover(json.RawMessage(raw))

			require.NoError(t, err)
			require.Equal(t, tt.want, c.Value)
		})
	}
}

func TestMarkdown(t *testing.T) {
	value := `"This method reverses a string \n\n"`
	c, err := NewCodeHover(json.RawMessage(value))

	require.NoError(t, err)
	require.Equal(t, "This method reverses a string \n\n", c.Value)
}
