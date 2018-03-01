package helper

import (
	"time"
)

// Clock interface provides the time
type Clock interface {
	Now() time.Time
}

// RealClock is the default time implementation
type RealClock struct{}

// Now returns the time
func (RealClock) Now() time.Time { return time.Now() }

// StubClock is the default time implementation
type StubClock struct {
	StubTime time.Time
}

// Now returns a stub time
func (c *StubClock) Now() time.Time { return c.StubTime }
