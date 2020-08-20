package objectstore

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"hash"
	"io"
	"strings"
	"time"

	"gitlab.com/gitlab-org/labkit/log"
)

// Upload represents an upload to an ObjectStorage provider
type Upload interface {
	io.WriteCloser
	ETag() string
}

// uploader is an io.WriteCloser that can be used as write end of the uploading pipe.
type uploader struct {
	// etag is the object storage provided checksum
	etag string

	// md5 is an optional hasher for calculating md5 on the fly
	md5 hash.Hash

	w io.Writer
	c io.Closer

	// uploadError is the last error occourred during upload
	uploadError error
	// ctx is the internal context bound to the upload request
	ctx context.Context

	pr       *io.PipeReader
	pw       *io.PipeWriter
	strategy uploadStrategy
	metrics  bool
}

func newUploader(strategy uploadStrategy) uploader {
	pr, pw := io.Pipe()
	return uploader{w: pw, c: pw, pr: pr, pw: pw, strategy: strategy, metrics: true}
}

func newMD5Uploader(strategy uploadStrategy, metrics bool) uploader {
	pr, pw := io.Pipe()
	hasher := md5.New()
	mw := io.MultiWriter(pw, hasher)
	return uploader{w: mw, c: pw, pr: pr, pw: pw, md5: hasher, strategy: strategy, metrics: metrics}
}

// Close implements the standard io.Closer interface: it closes the http client request.
// This method will also wait for the connection to terminate and return any error occurred during the upload
func (u *uploader) Close() error {
	if err := u.c.Close(); err != nil {
		return err
	}

	<-u.ctx.Done()

	if err := u.ctx.Err(); err == context.DeadlineExceeded {
		return err
	}

	return u.uploadError
}

func (u *uploader) Write(p []byte) (int, error) {
	return u.w.Write(p)
}

func (u *uploader) md5Sum() string {
	if u.md5 == nil {
		return ""
	}

	checksum := u.md5.Sum(nil)
	return hex.EncodeToString(checksum)
}

// ETag returns the checksum of the uploaded object returned by the ObjectStorage provider via ETag Header.
// This method will wait until upload context is done before returning.
func (u *uploader) ETag() string {
	<-u.ctx.Done()

	return u.etag
}

func (u *uploader) Execute(ctx context.Context, deadline time.Time) {
	if u.metrics {
		objectStorageUploadsOpen.Inc()
	}
	uploadCtx, cancelFn := context.WithDeadline(ctx, deadline)
	u.ctx = uploadCtx

	if u.metrics {
		go u.trackUploadTime()
	}
	go u.cleanup(ctx)
	go func() {
		defer cancelFn()
		if u.metrics {
			defer objectStorageUploadsOpen.Dec()
		}
		defer func() {
			// This will be returned as error to the next write operation on the pipe
			u.pr.CloseWithError(u.uploadError)
		}()

		err := u.strategy.Upload(uploadCtx, u.pr)
		if err != nil {
			u.uploadError = err
			if u.metrics {
				objectStorageUploadRequestsRequestFailed.Inc()
			}
			return
		}

		u.etag = u.strategy.ETag()

		if u.md5 != nil {
			err := compareMD5(u.md5Sum(), u.etag)
			if err != nil {
				log.ContextLogger(ctx).WithError(err).Error("error comparing MD5 checksum")

				u.uploadError = err
				if u.metrics {
					objectStorageUploadRequestsRequestFailed.Inc()
				}
			}
		}
	}()
}

func (u *uploader) trackUploadTime() {
	started := time.Now()
	<-u.ctx.Done()

	if u.metrics {
		objectStorageUploadTime.Observe(time.Since(started).Seconds())
	}
}

func (u *uploader) cleanup(ctx context.Context) {
	// wait for the upload to finish
	<-u.ctx.Done()

	if u.uploadError != nil {
		if u.metrics {
			objectStorageUploadRequestsRequestFailed.Inc()
		}
		u.strategy.Abort()
		return
	}

	// We have now successfully uploaded the file to object storage. Another
	// goroutine will hand off the object to gitlab-rails.
	<-ctx.Done()

	// gitlab-rails is now done with the object so it's time to delete it.
	u.strategy.Delete()
}

func compareMD5(local, remote string) error {
	if !strings.EqualFold(local, remote) {
		return fmt.Errorf("ETag mismatch. expected %q got %q", local, remote)
	}

	return nil
}
