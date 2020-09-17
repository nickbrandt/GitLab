package filestore

import (
	"context"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strconv"

	"github.com/dgrijalva/jwt-go"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/objectstore"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/secret"
)

type SizeError error

// ErrEntityTooLarge means that the uploaded content is bigger then maximum allowed size
var ErrEntityTooLarge = errors.New("entity is too large")

// FileHandler represent a file that has been processed for upload
// it may be either uploaded to an ObjectStore and/or saved on local path.
type FileHandler struct {
	// LocalPath is the path on the disk where file has been stored
	LocalPath string

	// RemoteID is the objectID provided by GitLab Rails
	RemoteID string
	// RemoteURL is ObjectStore URL provided by GitLab Rails
	RemoteURL string

	// Size is the persisted file size
	Size int64

	// Name is the resource name to send back to GitLab rails.
	// It differ from the real file name in order to avoid file collisions
	Name string

	// a map containing different hashes
	hashes map[string]string
}

type uploadClaims struct {
	Upload map[string]string `json:"upload"`
	jwt.StandardClaims
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
func (fh *FileHandler) GitLabFinalizeFields(prefix string) (map[string]string, error) {
	// TODO: remove `data` these once rails fully and exclusively support `signedData` (https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/263)
	data := make(map[string]string)
	signedData := make(map[string]string)
	key := func(field string) string {
		if prefix == "" {
			return field
		}

		return fmt.Sprintf("%s.%s", prefix, field)
	}

	for k, v := range map[string]string{
		"name":       fh.Name,
		"path":       fh.LocalPath,
		"remote_url": fh.RemoteURL,
		"remote_id":  fh.RemoteID,
		"size":       strconv.FormatInt(fh.Size, 10),
	} {
		data[key(k)] = v
		signedData[k] = v
	}

	for hashName, hash := range fh.hashes {
		data[key(hashName)] = hash
		signedData[hashName] = hash
	}

	claims := uploadClaims{Upload: signedData, StandardClaims: secret.DefaultClaims}
	jwtData, err := secret.JWTTokenString(claims)
	if err != nil {
		return nil, err
	}
	data[key("gitlab-workhorse-upload")] = jwtData

	return data, nil
}

// Upload represents a destination where we store an upload
type uploadWriter interface {
	io.WriteCloser
	CloseWithError(error) error
	ETag() string
}

// SaveFileFromReader persists the provided reader content to all the location specified in opts. A cleanup will be performed once ctx is Done
// Make sure the provided context will not expire before finalizing upload with GitLab Rails.
func SaveFileFromReader(ctx context.Context, reader io.Reader, size int64, opts *SaveFileOpts) (fh *FileHandler, err error) {
	var uploadWriter uploadWriter
	fh = &FileHandler{
		Name:      opts.TempFilePrefix,
		RemoteID:  opts.RemoteID,
		RemoteURL: opts.RemoteURL,
	}
	hashes := newMultiHash()
	writers := []io.Writer{hashes.Writer}
	defer func() {
		for _, w := range writers {
			if closer, ok := w.(io.WriteCloser); ok {
				closer.Close()
			}
		}
	}()

	var clientMode string

	switch {
	case opts.IsLocal():
		clientMode = "local"
		uploadWriter, err = fh.uploadLocalFile(ctx, opts)
	case opts.UseWorkhorseClientEnabled() && opts.ObjectStorageConfig.IsGoCloud():
		clientMode = fmt.Sprintf("go_cloud:%s", opts.ObjectStorageConfig.Provider)
		p := &objectstore.GoCloudObjectParams{
			Ctx:        ctx,
			Mux:        opts.ObjectStorageConfig.URLMux,
			BucketURL:  opts.ObjectStorageConfig.GoCloudConfig.URL,
			ObjectName: opts.RemoteTempObjectID,
			Deadline:   opts.Deadline,
		}
		uploadWriter, err = objectstore.NewGoCloudObject(p)
	case opts.UseWorkhorseClientEnabled() && opts.ObjectStorageConfig.IsAWS() && opts.ObjectStorageConfig.IsValid():
		clientMode = "s3"
		uploadWriter, err = objectstore.NewS3Object(
			ctx,
			opts.RemoteTempObjectID,
			opts.ObjectStorageConfig.S3Credentials,
			opts.ObjectStorageConfig.S3Config,
			opts.Deadline,
		)
	case opts.IsMultipart():
		clientMode = "multipart"
		uploadWriter, err = objectstore.NewMultipart(
			ctx,
			opts.PresignedParts,
			opts.PresignedCompleteMultipart,
			opts.PresignedAbortMultipart,
			opts.PresignedDelete,
			opts.PutHeaders,
			opts.Deadline,
			opts.PartSize,
		)
	default:
		clientMode = "http"
		uploadWriter, err = objectstore.NewObject(
			ctx,
			opts.PresignedPut,
			opts.PresignedDelete,
			opts.PutHeaders,
			opts.Deadline,
			size,
		)
	}

	if err != nil {
		return nil, err
	}

	writers = append(writers, uploadWriter)

	defer func() {
		if err != nil {
			uploadWriter.CloseWithError(err)
		}
	}()

	if opts.MaximumSize > 0 {
		if size > opts.MaximumSize {
			return nil, SizeError(fmt.Errorf("the upload size %d is over maximum of %d bytes", size, opts.MaximumSize))
		}

		// We allow to read an extra byte to check later if we exceed the max size
		reader = &io.LimitedReader{R: reader, N: opts.MaximumSize + 1}
	}

	multiWriter := io.MultiWriter(writers...)
	fh.Size, err = io.Copy(multiWriter, reader)
	if err != nil {
		return nil, err
	}

	if opts.MaximumSize > 0 && fh.Size > opts.MaximumSize {
		// An extra byte was read thus exceeding the max size
		return nil, ErrEntityTooLarge
	}

	if size != -1 && size != fh.Size {
		return nil, SizeError(fmt.Errorf("expected %d bytes but got only %d", size, fh.Size))
	}

	logger := log.WithContextFields(ctx, log.Fields{
		"copied_bytes":     fh.Size,
		"is_local":         opts.IsLocal(),
		"is_multipart":     opts.IsMultipart(),
		"is_remote":        !opts.IsLocal(),
		"remote_id":        opts.RemoteID,
		"temp_file_prefix": opts.TempFilePrefix,
		"client_mode":      clientMode,
	})

	if opts.IsLocal() {
		logger = logger.WithField("local_temp_path", opts.LocalTempPath)
	} else {
		logger = logger.WithField("remote_temp_object", opts.RemoteTempObjectID)
	}

	logger.Info("saved file")

	fh.hashes = hashes.finish()

	// we need to close the writer in order to get ETag header
	err = uploadWriter.Close()
	if err != nil {
		if err == objectstore.ErrNotEnoughParts {
			return nil, ErrEntityTooLarge
		}
		return nil, err
	}

	etag := uploadWriter.ETag()
	fh.hashes["etag"] = etag

	return fh, err
}

func (fh *FileHandler) uploadLocalFile(ctx context.Context, opts *SaveFileOpts) (uploadWriter, error) {
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
	return &nopUpload{file}, nil
}

type nopUpload struct{ io.WriteCloser }

func (nop *nopUpload) CloseWithError(error) error { return nop.Close() }
func (nop *nopUpload) ETag() string               { return "" }

// SaveFileFromDisk open the local file fileName and calls SaveFileFromReader
func SaveFileFromDisk(ctx context.Context, fileName string, opts *SaveFileOpts) (fh *FileHandler, err error) {
	file, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	fi, err := file.Stat()
	if err != nil {
		return nil, err
	}

	return SaveFileFromReader(ctx, file, fi.Size(), opts)
}
