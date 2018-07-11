package log

import (
	"bytes"
	"context"
	"crypto/rand"
	"fmt"
	"math"
	"math/big"
	"net/http"
	"time"
)

type ctxKey string

const (
	// KeyCorrelationID const is the context key for Correlation ID
	KeyCorrelationID ctxKey = "X-Correlation-ID"

	base62Chars string = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
)

var (
	randMax    = big.NewInt(math.MaxInt64)
	randSource = rand.Reader
)

func InjectCorrelationID(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		parent := r.Context()
		correlationID, err := generateRandomCorrelationID()
		if err != nil {
			correlationID = fmt.Sprintf("E:%s:%s", r.RemoteAddr, encodeReverseBase62(time.Now().UnixNano()))
			NoContext().WithError(err).Warning("Can't generate random correlation-id")
		}

		ctx := context.WithValue(parent, KeyCorrelationID, correlationID)
		h.ServeHTTP(w, r.WithContext(ctx))
	})
}

func generateRandomCorrelationID() (string, error) {
	id, err := rand.Int(randSource, randMax)
	if err != nil {
		return "", err
	}
	base62 := encodeReverseBase62(id.Int64())

	return base62, nil
}

// encodeReverseBase62 encodes num into its Base62 reversed representation.
// The most significant value is at the end of the string.
//
// Appending is faster than prepending and this is enough for the purpose of a random ID
func encodeReverseBase62(num int64) string {
	if num == 0 {
		return "0"
	}

	encoded := bytes.Buffer{}
	for q := num; q > 0; q /= 62 {
		encoded.Write([]byte{base62Chars[q%62]})
	}

	return encoded.String()
}
