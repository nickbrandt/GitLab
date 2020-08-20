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
}

const maxImageScalerProcs = 100

var numScalerProcs int32 = 0

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

var imageResizeConcurrencyMax = prometheus.NewCounter(
	prometheus.CounterOpts{
		Name: "gitlab_workhorse_max_image_resize_requests_exceeded_total",
		Help: "Amount of image resizing requests that exceed the maximum allowed scaler processes",
	},
)

func init() {
	prometheus.MustRegister(imageResizeConcurrencyMax)
}

// This Injecter forks into graphicsmagick to resize an image identified by path or URL
// and streams the resized image back to the client
func (r *resizer) Inject(w http.ResponseWriter, req *http.Request, paramsData string) {
	logger := log.ContextLogger(req.Context())
	params, err := r.unpackParameters(paramsData)
	if err != nil {
		// This means the response header coming from Rails was malformed; there is no way
		// to sensibly recover from this other than failing fast
		helper.Fail500(w, req, fmt.Errorf("ImageResizer: Failed reading image resize params: %v", err))
		return
	}

	sourceImageReader, err := openSourceImage(params.Location)
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

	w.Header().Del("Content-Length")
	bytesWritten, err := io.Copy(w, imageReader)
	if err != nil {
		helper.Fail500(w, req, err)
		return
	}

	logger.WithField("bytes_written", bytesWritten).Print("ImageResizer: success")
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
	// Only allow more scaling requests if we haven't yet reached the maximum allows number
	// of concurrent graphicsmagick processes
	if n := atomic.AddInt32(&numScalerProcs, 1); n > maxImageScalerProcs {
		atomic.AddInt32(&numScalerProcs, -1)
		imageResizeConcurrencyMax.Inc()
		return r, nil
	}

	go func() {
		<-ctx.Done()
		atomic.AddInt32(&numScalerProcs, -1)
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

func openSourceImage(location string) (io.ReadCloser, error) {
	if !isURL(location) {
		return os.Open(location)
	}

	res, err := httpClient.Get(location)
	if err != nil {
		return nil, err
	}

	if res.StatusCode != http.StatusOK {
		res.Body.Close()

		return nil, fmt.Errorf("ImageResizer: cannot read data from %q: %d %s",
			location, res.StatusCode, res.Status)
	}

	return res.Body, nil
}
