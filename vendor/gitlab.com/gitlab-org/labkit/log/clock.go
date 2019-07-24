package log

import (
	"time"
)

// Clock interface provides the time
type clock interface {
	Now() time.Time
}

// realClock is the default time implementation
type realClock struct{}

// Now returns the time
func (realClock) Now() time.Time { return time.Now() }

// stubClock is the default time implementation
type stubClock struct {
	StubTime time.Time
}

// Now returns a stub time
func (c *stubClock) Now() time.Time { return c.StubTime }
