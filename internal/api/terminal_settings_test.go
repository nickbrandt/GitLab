package api

import (
	"net/http"
	"testing"
)

func terminal(url string, subprotocols ...string) *TerminalSettings {
	return &TerminalSettings{
		Url:          url,
		Subprotocols: subprotocols,
	}
}

func ca(term *TerminalSettings) *TerminalSettings {
	term = term.Clone()
	term.CAPem = "Valid CA data"

	return term
}

func header(term *TerminalSettings, values ...string) *TerminalSettings {
	if len(values) == 0 {
		values = []string{"Dummy Value"}
	}

	term = term.Clone()
	term.Header = http.Header{
		"Header": values,
	}

	return term
}

func TestClone(t *testing.T) {
	a := ca(header(terminal("ws:", "", "")))
	b := a.Clone()

	if a == b {
		t.Fatalf("Address of cloned terminal didn't change")
	}

	if &a.Subprotocols == &b.Subprotocols {
		t.Fatalf("Address of cloned subprotocols didn't change")
	}

	if &a.Header == &b.Header {
		t.Fatalf("Address of cloned header didn't change")
	}
}

func TestValidate(t *testing.T) {
	for i, tc := range []struct {
		terminal *TerminalSettings
		valid    bool
		msg      string
	}{
		{nil, false, "nil terminal"},
		{terminal("", ""), false, "empty URL"},
		{terminal("ws:"), false, "empty subprotocols"},
		{terminal("ws:", "foo"), true, "any subprotocol"},
		{terminal("ws:", "foo", "bar"), true, "multiple subprotocols"},
		{terminal("ws:", ""), true, "websocket URL"},
		{terminal("wss:", ""), true, "secure websocket URL"},
		{terminal("http:", ""), false, "HTTP URL"},
		{terminal("https:", ""), false, " HTTPS URL"},
		{ca(terminal("ws:", "")), true, "any CA pem"},
		{header(terminal("ws:", "")), true, "any headers"},
		{ca(header(terminal("ws:", ""))), true, "PEM and headers"},
	} {
		if err := tc.terminal.Validate(); (err != nil) == tc.valid {
			t.Fatalf("test case %d: "+tc.msg+": valid=%v: %s: %+v", i, tc.valid, err, tc.terminal)
		}
	}
}

func TestDialer(t *testing.T) {
	terminal := terminal("ws:", "foo")
	dialer := terminal.Dialer()

	if len(dialer.Subprotocols) != len(terminal.Subprotocols) {
		t.Fatalf("Subprotocols don't match: %+v vs. %+v", terminal.Subprotocols, dialer.Subprotocols)
	}

	for i, subprotocol := range terminal.Subprotocols {
		if dialer.Subprotocols[i] != subprotocol {
			t.Fatalf("Subprotocols don't match: %+v vs. %+v", terminal.Subprotocols, dialer.Subprotocols)
		}
	}

	if dialer.TLSClientConfig != nil {
		t.Fatalf("Unexpected TLSClientConfig: %+v", dialer)
	}

	terminal = ca(terminal)
	dialer = terminal.Dialer()

	if dialer.TLSClientConfig == nil || dialer.TLSClientConfig.RootCAs == nil {
		t.Fatalf("Custom CA certificates not recognised!")
	}
}

func TestIsEqual(t *testing.T) {
	term := terminal("ws:", "foo")

	term_header2 := header(term, "extra")
	term_header3 := header(term)
	term_header3.Header.Add("Extra", "extra")

	term_ca2 := ca(term)
	term_ca2.CAPem = "other value"

	for i, tc := range []struct {
		termA    *TerminalSettings
		termB    *TerminalSettings
		expected bool
	}{
		{nil, nil, true},
		{term, nil, false},
		{nil, term, false},
		{term, term, true},
		{term.Clone(), term.Clone(), true},
		{term, terminal("foo:"), false},
		{term, terminal(term.Url), false},
		{header(term), header(term), true},
		{term_header2, term_header2, true},
		{term_header3, term_header3, true},
		{header(term), term_header2, false},
		{header(term), term_header3, false},
		{header(term), term, false},
		{term, header(term), false},
		{ca(term), ca(term), true},
		{ca(term), term, false},
		{term, ca(term), false},
		{ca(header(term)), ca(header(term)), true},
		{term_ca2, ca(term), false},
	} {
		if actual := tc.termA.IsEqual(tc.termB); tc.expected != actual {
			t.Fatalf(
				"test case %d: Comparison:\n-%+v\n+%+v\nexpected=%v: actual=%v",
				i, tc.termA, tc.termB, tc.expected, actual,
			)
		}
	}
}
