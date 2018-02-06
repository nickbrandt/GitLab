package filestore

// SaveFileOpts represents all the options available for saving a file to object store
type SaveFileOpts struct {
	// TempFilePrefix is the prefix used to create temporary local file
	TempFilePrefix string
	// LocalTempPath is the directory where to write a local copy of the file
	LocalTempPath string
}

// IsLocal checks if the options require the writing of the file on disk
func (s *SaveFileOpts) IsLocal() bool {
	return s.LocalTempPath != ""
}
