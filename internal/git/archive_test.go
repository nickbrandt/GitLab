package git

import (
	"testing"
)

func TestParseBasename(t *testing.T) {
	for _, testCase := range []struct{ in, out string }{
		{"", "tar.gz"},
		{".tar.gz", "tar.gz"},
		{".tgz", "tar.gz"},
		{".gz", "tar.gz"},
		{".tar.bz2", "tar.bz2"},
		{".tbz", "tar.bz2"},
		{".tbz2", "tar.bz2"},
		{".tb2", "tar.bz2"},
		{".bz2", "tar.bz2"},
	} {
		basename := "archive" + testCase.in
		out, ok := parseBasename(basename)
		if !ok {
			t.Fatalf("parseBasename did not recognize %q", basename)
		}

		if out != testCase.out {
			t.Fatalf("expected %q, got %q", testCase.out, out)
		}
	}
}
