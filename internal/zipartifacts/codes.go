package zipartifacts

// These are exit codes used by subprocesses in cmd/gitlab-zip-xxx
const (
	StatusNotZip = 10 + iota
	StatusEntryNotFound
)
