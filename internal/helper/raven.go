package helper

import (
	"net/http"
	"reflect"
	"strings"

	"github.com/getsentry/raven-go"
)

func captureRavenError(r *http.Request, err error) {
	client := raven.DefaultClient

	interfaces := []raven.Interface{}
	if r != nil {
		CleanHeadersForRaven(r)
		interfaces = append(interfaces, raven.NewHttp(r))
	}

	exception := &raven.Exception{
		Stacktrace: raven.NewStacktrace(2, 3, nil),
		Value:      err.Error(),
		Type:       reflect.TypeOf(err).String(),
	}
	interfaces = append(interfaces, exception)

	packet := raven.NewPacket(err.Error(), interfaces...)
	client.Capture(packet, nil)
}

func CleanHeadersForRaven(r *http.Request) {
	if auth := r.Header.Get("Authorization"); auth != "" {
		if authSplit := strings.Split(auth, " "); authSplit != nil {
			r.Header.Set("Authorization", authSplit[0]+" [redacted]")
		}
	}
}
