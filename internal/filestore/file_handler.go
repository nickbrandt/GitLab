package filestore

import (
	"context"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strconv"
)

// FileHandler represent a file that has been processed for upload
// it may be either uploaded to an ObjectStore and/or saved on local path.
// Remote upload is not yet implemented
type FileHandler struct {
	// LocalPath is the path on the disk where file has been stored
	LocalPath string

	// Size is the persisted file size
	Size int64

	// Name is the resource name to send back to GitLab rails.
	// It differ from the real file name in order to avoid file collisions
	Name string

	// a map containing different hashes
	hashes map[string]string
}

// SHA256 hash of the handled file
func (fh *FileHandler) SHA256() string {
	return fh.hashes["sha256"]
}

// MD5 hash of the handled file
func (fh *FileHandler) MD5() string {
	return fh.hashes["md5"]
}

// GitLabFinalizeFields returns a map with all the fields GitLab Rails needs in order to finalize the upload.
func (fh *FileHandler) GitLabFinalizeFields(prefix string) map[string]string {
	data := make(map[string]string)
	key := func(field string) string {
		if prefix == "" {
			return field
		}

		return fmt.Sprintf("%s.%s", prefix, field)
	}

	if fh.Name != "" {
		data[key("name")] = fh.Name
	}
	if fh.LocalPath != "" {
		data[key("path")] = fh.LocalPath
	}
	data[key("size")] = strconv.FormatInt(fh.Size, 10)
	for hashName, hash := range fh.hashes {
		data[key(hashName)] = hash
	}

	return data
}

// SaveFileFromReader persists the provided reader content to all the location specified in opts. A cleanup will be performed once ctx is Done
// Make sure the provided context will not expire before finalizing upload with GitLab Rails.
func SaveFileFromReader(ctx context.Context, reader io.Reader, size int64, opts *SaveFileOpts) (fh *FileHandler, err error) {
	fh = &FileHandler{Name: opts.TempFilePrefix}
	hashes := newMultiHash()
	writers := []io.Writer{hashes.Writer}
	defer func() {
		for _, w := range writers {
			if closer, ok := w.(io.WriteCloser); ok {
				closer.Close()
			}
		}
	}()

	if opts.IsLocal() {
		fileWriter, err := fh.uploadLocalFile(ctx, opts)
		if err != nil {
			return nil, err
		}

		writers = append(writers, fileWriter)
	}

	if len(writers) == 1 {
		return nil, errors.New("Missing upload destination")
	}

	multiWriter := io.MultiWriter(writers...)
	fh.Size, err = io.Copy(multiWriter, reader)
	if err != nil {
		return nil, err
	}

	if size != -1 && size != fh.Size {
		return nil, fmt.Errorf("Expected %d bytes but got only %d", size, fh.Size)
	}

	fh.hashes = hashes.finish()

	return fh, err
}

func (fh *FileHandler) uploadLocalFile(ctx context.Context, opts *SaveFileOpts) (io.WriteCloser, error) {
	// make sure TempFolder exists
	err := os.MkdirAll(opts.LocalTempPath, 0700)
	if err != nil {
		return nil, fmt.Errorf("uploadLocalFile: mkdir %q: %v", opts.LocalTempPath, err)
	}

	file, err := ioutil.TempFile(opts.LocalTempPath, opts.TempFilePrefix)
	if err != nil {
		return nil, fmt.Errorf("uploadLocalFile: create file: %v", err)
	}

	go func() {
		<-ctx.Done()
		os.Remove(file.Name())
	}()

	fh.LocalPath = file.Name()
	return file, nil
}
