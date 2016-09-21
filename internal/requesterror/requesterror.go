package requesterror

import (
	"fmt"
	"net/http"
)

// For errors that occur while handling an HTTP request it is often
// relevant what the request was for. This helper lets us consistently
// embed request metadata in the error message.
func New(context string, r *http.Request, format string, a ...interface{}) error {
	return fmt.Errorf("%s: %s %q: %s", context, r.Method, r.RequestURI, fmt.Sprintf(format, a...))
}
