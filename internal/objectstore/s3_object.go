package objectstore

import (
	"context"
	"io"
	"time"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"

	"github.com/aws/aws-sdk-go/aws"

	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"

	"gitlab.com/gitlab-org/labkit/log"
)

type S3Object struct {
	credentials config.S3Credentials
	config      config.S3Config
	objectName  string
	uploader
}

func setEncryptionOptions(input *s3manager.UploadInput, s3Config config.S3Config) {
	if s3Config.ServerSideEncryption != "" {
		input.ServerSideEncryption = aws.String(s3Config.ServerSideEncryption)

		if s3Config.ServerSideEncryption == s3.ServerSideEncryptionAwsKms && s3Config.SSEKMSKeyID != "" {
			input.SSEKMSKeyId = aws.String(s3Config.SSEKMSKeyID)
		}
	}
}

func NewS3Object(ctx context.Context, objectName string, s3Credentials config.S3Credentials, s3Config config.S3Config, deadline time.Time) (*S3Object, error) {
	pr, pw := io.Pipe()
	objectStorageUploadsOpen.Inc()
	uploadCtx, cancelFn := context.WithDeadline(ctx, deadline)

	o := &S3Object{
		uploader:    newUploader(uploadCtx, pw),
		credentials: s3Credentials,
		config:      s3Config,
	}

	go o.trackUploadTime()
	go o.cleanup(ctx)

	go func() {
		defer cancelFn()
		defer objectStorageUploadsOpen.Dec()
		defer func() {
			// This will be returned as error to the next write operation on the pipe
			pr.CloseWithError(o.uploadError)
		}()

		sess, err := setupS3Session(s3Credentials, s3Config)
		if err != nil {
			o.uploadError = err
			log.WithError(err).Error("error creating S3 session")
			return
		}

		o.objectName = objectName
		uploader := s3manager.NewUploader(sess)

		input := &s3manager.UploadInput{
			Bucket: aws.String(s3Config.Bucket),
			Key:    aws.String(objectName),
			Body:   pr,
		}

		setEncryptionOptions(input, s3Config)

		_, err = uploader.UploadWithContext(uploadCtx, input)
		if err != nil {
			o.uploadError = err
			objectStorageUploadRequestsRequestFailed.Inc()
			log.WithError(err).Error("error uploading S3 session")
			return
		}
	}()

	return o, nil
}

func (o *S3Object) trackUploadTime() {
	started := time.Now()
	<-o.ctx.Done()
	objectStorageUploadTime.Observe(time.Since(started).Seconds())
}

func (o *S3Object) cleanup(ctx context.Context) {
	// wait for the upload to finish
	<-o.ctx.Done()

	if o.uploadError != nil {
		objectStorageUploadRequestsRequestFailed.Inc()
		o.delete()
		return
	}

	// We have now successfully uploaded the file to object storage. Another
	// goroutine will hand off the object to gitlab-rails.
	<-ctx.Done()

	// gitlab-rails is now done with the object so it's time to delete it.
	o.delete()
}

func (o *S3Object) delete() {
	if o.objectName == "" {
		return
	}

	session, err := setupS3Session(o.credentials, o.config)
	if err != nil {
		log.WithError(err).Error("error setting up S3 session in delete")
		return
	}

	svc := s3.New(session)
	input := &s3.DeleteObjectInput{
		Bucket: aws.String(o.config.Bucket),
		Key:    aws.String(o.objectName),
	}

	// Note we can't use the request context because in a successful
	// case, the original request has already completed.
	deleteCtx, cancel := context.WithTimeout(context.Background(), 60*time.Second) // lint:allow context.Background
	defer cancel()

	_, err = svc.DeleteObjectWithContext(deleteCtx, input)
	if err != nil {
		log.WithError(err).Error("error deleting S3 object", err)
	}
}
