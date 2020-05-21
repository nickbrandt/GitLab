package upload

import (
	"context"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"strings"

	"github.com/prometheus/client_golang/prometheus"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/lsif_transformer/parser"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/upload/exif"
)

// ErrInjectedClientParam means that the client sent a parameter that overrides one of our own fields
var ErrInjectedClientParam = errors.New("injected client parameter")

var (
	multipartUploadRequests = prometheus.NewCounterVec(
		prometheus.CounterOpts{

			Name: "gitlab_workhorse_multipart_upload_requests",
			Help: "How many multipart upload requests have been processed by gitlab-workhorse. Partitioned by type.",
		},
		[]string{"type"},
	)

	multipartFileUploadBytes = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_multipart_upload_bytes",
			Help: "How many disk bytes of multipart file parts have been successfully written by gitlab-workhorse. Partitioned by type.",
		},
		[]string{"type"},
	)

	multipartFiles = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_multipart_upload_files",
			Help: "How many multipart file parts have been processed by gitlab-workhorse. Partitioned by type.",
		},
		[]string{"type"},
	)
)

type rewriter struct {
	writer          *multipart.Writer
	preauth         *api.Response
	filter          MultipartFormProcessor
	finalizedFields map[string]bool
}

func init() {
	prometheus.MustRegister(multipartUploadRequests)
	prometheus.MustRegister(multipartFileUploadBytes)
	prometheus.MustRegister(multipartFiles)
}

func rewriteFormFilesFromMultipart(r *http.Request, writer *multipart.Writer, preauth *api.Response, filter MultipartFormProcessor) error {
	// Create multipart reader
	reader, err := r.MultipartReader()
	if err != nil {
		if err == http.ErrNotMultipart {
			// We want to be able to recognize http.ErrNotMultipart elsewhere so no fmt.Errorf
			return http.ErrNotMultipart
		}
		return fmt.Errorf("get multipart reader: %v", err)
	}

	multipartUploadRequests.WithLabelValues(filter.Name()).Inc()

	rew := &rewriter{
		writer:          writer,
		preauth:         preauth,
		filter:          filter,
		finalizedFields: make(map[string]bool),
	}

	for {
		p, err := reader.NextPart()
		if err != nil {
			if err == io.EOF {
				break
			}
			return err
		}

		name := p.FormName()
		if name == "" {
			continue
		}

		if rew.finalizedFields[name] {
			return ErrInjectedClientParam
		}

		if p.FileName() != "" {
			err = rew.handleFilePart(r.Context(), name, p)
		} else {
			err = rew.copyPart(r.Context(), name, p)
		}

		if err != nil {
			return err
		}
	}

	return nil
}

func (rew *rewriter) handleFilePart(ctx context.Context, name string, p *multipart.Part) error {
	multipartFiles.WithLabelValues(rew.filter.Name()).Inc()

	filename := p.FileName()

	if strings.Contains(filename, "/") || filename == "." || filename == ".." {
		return fmt.Errorf("illegal filename: %q", filename)
	}

	opts := filestore.GetOpts(rew.preauth)
	opts.TempFilePrefix = filename

	var inputReader io.Reader
	if exif.IsExifFile(filename) {
		log.WithContextFields(ctx, log.Fields{
			"filename": filename,
		}).Print("running exiftool to remove any metadata")

		cleaner, err := exif.NewCleaner(ctx, p)
		if err != nil {
			return fmt.Errorf("failed to start EXIF metadata cleaner: %v", err)
		}

		inputReader = cleaner
	} else {
		inputReader = p
	}

	inputReader, err := rew.handleLsifUpload(inputReader, opts.LocalTempPath)
	if err != nil {
		return err
	}

	fh, err := filestore.SaveFileFromReader(ctx, inputReader, -1, opts)
	if err != nil {
		switch err {
		case filestore.ErrEntityTooLarge, exif.ErrRemovingExif:
			return err
		default:
			return fmt.Errorf("persisting multipart file: %v", err)
		}
	}

	fields, err := fh.GitLabFinalizeFields(name)
	if err != nil {
		return fmt.Errorf("failed to finalize fields: %v", err)
	}

	for key, value := range fields {
		rew.writer.WriteField(key, value)
		rew.finalizedFields[key] = true
	}

	multipartFileUploadBytes.WithLabelValues(rew.filter.Name()).Add(float64(fh.Size))

	return rew.filter.ProcessFile(ctx, name, fh, rew.writer)
}

func (rew *rewriter) handleLsifUpload(reader io.Reader, tempPath string) (io.Reader, error) {
	if rew.preauth.ProcessLsif {
		p, err := parser.NewParser(reader, tempPath)
		if err != nil {
			return nil, err
		}

		z, err := p.ZipReader()
		if err != nil {
			return nil, err
		}

		if err := p.Close(); err != nil {
			return nil, err
		}

		return z, nil
	}

	return reader, nil
}

func (rew *rewriter) copyPart(ctx context.Context, name string, p *multipart.Part) error {
	np, err := rew.writer.CreatePart(p.Header)
	if err != nil {
		return fmt.Errorf("create multipart field: %v", err)
	}

	if _, err := io.Copy(np, p); err != nil {
		return fmt.Errorf("duplicate multipart field: %v", err)
	}

	if err := rew.filter.ProcessField(ctx, name, rew.writer); err != nil {
		return fmt.Errorf("process multipart field: %v", err)
	}

	return nil
}
