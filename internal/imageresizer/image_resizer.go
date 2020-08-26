package imageresizer

import (
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/labkit/tracing"

	"github.com/sirupsen/logrus"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/senddata"
)

type resizer struct{ senddata.Prefix }

var SendScaledImage = &resizer{"send-scaled-img:"}

type resizeParams struct {
	Location string
	Width    uint
	Format   string
}

type processCounter struct {
	n int32
}

var numScalerProcs processCounter

const maxImageScalerProcs = 100

// Images might be located remotely in object storage, in which case we need to stream
// it via http(s)
var httpTransport = tracing.NewRoundTripper(correlation.NewInstrumentedRoundTripper(&http.Transport{
	Proxy: http.ProxyFromEnvironment,
	DialContext: (&net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 10 * time.Second,
	}).DialContext,
	MaxIdleConns:          2,
	IdleConnTimeout:       30 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ExpectContinueTimeout: 10 * time.Second,
	ResponseHeaderTimeout: 30 * time.Second,
}))

var httpClient = &http.Client{
	Transport: httpTransport,
}

var (
	imageResizeConcurrencyLimitExceeds = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_image_resize_concurrency_limit_exceeds_total",
			Help: "Amount of image resizing requests that exceeded the maximum allowed scaler processes",
		},
	)
	imageResizeProcesses = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "gitlab_workhorse_image_resize_processes",
			Help: "Amount of image resizing scaler processes working now",
		},
	)
	imageResizeCompleted = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_image_resize_completed_total",
			Help: "Amount of image resizing processes sucessfully completed",
		},
	)
)

func init() {
	prometheus.MustRegister(imageResizeConcurrencyLimitExceeds)
	prometheus.MustRegister(imageResizeProcesses)
	prometheus.MustRegister(imageResizeCompleted)
}

// This Injecter forks into graphicsmagick to resize an image identified by path or URL
// and streams the resized image back to the client
func (r *resizer) Inject(w http.ResponseWriter, req *http.Request, paramsData string) {
	start := time.Now()
	logger := log.ContextLogger(req.Context())
	params, err := r.unpackParameters(paramsData)
	if err != nil {
		// This means the response header coming from Rails was malformed; there is no way
		// to sensibly recover from this other than failing fast
		helper.Fail500(w, req, fmt.Errorf("ImageResizer: Failed reading image resize params: %v", err))
		return
	}

	sourceImageReader, filesize, err := openSourceImage(params.Location)
	if err != nil {
		// This means we cannot even read the input image; fail fast.
		helper.Fail500(w, req, fmt.Errorf("ImageResizer: Failed opening image data stream: %v", err))
		return
	}
	defer sourceImageReader.Close()

	// Past this point we attempt to rescale the image; if this should fail for any reason, we
	// simply fail over to rendering out the original image unchanged.
	imageReader, resizeCmd := tryResizeImage(req.Context(), sourceImageReader, params.Width, logger)
	defer helper.CleanUpProcessGroup(resizeCmd)
	imageResizeCompleted.Inc()

	w.Header().Del("Content-Length")
	bytesWritten, err := io.Copy(w, imageReader)
	if err != nil {
		helper.Fail500(w, req, err)
		return
	}

	logger.WithFields(log.Fields{
		"bytes_written":     bytesWritten,
		"duration_s":        time.Since(start).Seconds(),
		"target_width":      params.Width,
		"format":            params.Format,
		"original_filesize": filesize,
	}).Printf("ImageResizer: Success")
}

func (r *resizer) unpackParameters(paramsData string) (*resizeParams, error) {
	var params resizeParams
	if err := r.Unpack(&params, paramsData); err != nil {
		return nil, err
	}

	if params.Location == "" {
		return nil, fmt.Errorf("ImageResizer: Location is empty")
	}

	return &params, nil
}

// Attempts to rescale the given image data, or in case of errors, falls back to the original image.
func tryResizeImage(ctx context.Context, r io.Reader, width uint, logger *logrus.Entry) (io.Reader, *exec.Cmd) {
	if !numScalerProcs.tryIncrement() {
		return r, nil
	}

	go func() {
		<-ctx.Done()
		numScalerProcs.decrement()
	}()

	resizeCmd, resizedImageReader, err := startResizeImageCommand(ctx, r, logger.Writer(), width)
	if err != nil {
		logger.WithError(err).Error("ImageResizer: failed forking into graphicsmagick")
		return r, nil
	}
	return resizedImageReader, resizeCmd
}

func startResizeImageCommand(ctx context.Context, imageReader io.Reader, errorWriter io.Writer, width uint) (*exec.Cmd, io.ReadCloser, error) {
	cmd := exec.CommandContext(ctx, "gm", "convert", "-resize", fmt.Sprintf("%dx", width), "-", "-")
	cmd.Stdin = imageReader
	cmd.Stderr = errorWriter
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, nil, err
	}

	if err := cmd.Start(); err != nil {
		return nil, nil, err
	}

	return cmd, stdout, nil
}

func isURL(location string) bool {
	return strings.HasPrefix(location, "http://") || strings.HasPrefix(location, "https://")
}

func openSourceImage(location string) (io.ReadCloser, int64, error) {
	if isURL(location) {
		return openFromUrl(location)
	}

	return openFromFile(location)
}

func openFromUrl(location string) (io.ReadCloser, int64, error) {
	res, err := httpClient.Get(location)
	if err != nil {
		return nil, 0, err
	}

	if res.StatusCode != http.StatusOK {
		res.Body.Close()

		return nil, 0, fmt.Errorf("ImageResizer: cannot read data from %q: %d %s",
			location, res.StatusCode, res.Status)
	}

	return res.Body, res.ContentLength, nil
}

func openFromFile(location string) (io.ReadCloser, int64, error) {
	file, err := os.Open(location)

	if err != nil {
		return file, 0, err
	}

	fi, err := file.Stat()
	if err != nil {
		return file, 0, err
	}

	return file, fi.Size(), nil
}

// Only allow more scaling requests if we haven't yet reached the maximum
// allowed number of concurrent scaler processes
func (c *processCounter) tryIncrement() bool {
	if p := atomic.AddInt32(&c.n, 1); p > maxImageScalerProcs {
		c.decrement()
		imageResizeConcurrencyLimitExceeds.Inc()

		return false
	}

	imageResizeProcesses.Set(float64(c.n))
	return true
}

func (c *processCounter) decrement() {
	atomic.AddInt32(&c.n, -1)
	imageResizeProcesses.Set(float64(c.n))
}
