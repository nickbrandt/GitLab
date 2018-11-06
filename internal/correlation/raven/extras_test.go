package raven

import (
	"context"
	"reflect"
	"testing"

	raven "github.com/getsentry/raven-go"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/correlation"
)

func TestSetExtra(t *testing.T) {

	tests := []struct {
		name  string
		ctx   context.Context
		extra raven.Extra
		want  raven.Extra
	}{
		{
			name:  "trivial",
			ctx:   nil,
			extra: nil,
			want:  raven.Extra{},
		},
		{
			name: "no_context",
			ctx:  nil,
			extra: map[string]interface{}{
				"key": "value",
			},
			want: map[string]interface{}{
				"key": "value",
			},
		},
		{
			name: "context",
			ctx:  correlation.ContextWithCorrelation(context.Background(), "C001"),
			extra: map[string]interface{}{
				"key": "value",
			},
			want: map[string]interface{}{
				"key":               "value",
				ravenSentryExtraKey: "C001",
			},
		},
		{
			name:  "no_injected_extras",
			ctx:   correlation.ContextWithCorrelation(context.Background(), "C001"),
			extra: nil,
			want: map[string]interface{}{
				ravenSentryExtraKey: "C001",
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := SetExtra(tt.ctx, tt.extra); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("SetExtra() = %v, want %v", got, tt.want)
			}
		})
	}
}
