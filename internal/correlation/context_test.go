package correlation

import (
	"context"
	"testing"
)

func TestExtractFromContext(t *testing.T) {
	tests := []struct {
		name string
		ctx  context.Context
		want string
	}{
		{"nil", nil, ""},
		{"missing", context.Background(), ""},
		{"set", context.WithValue(context.Background(), keyCorrelationID, "CORRELATION_ID"), "CORRELATION_ID"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := ExtractFromContext(tt.ctx); got != tt.want {
				t.Errorf("ExtractFromContext() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestContextWithCorrelation(t *testing.T) {
	tests := []struct {
		name          string
		ctx           context.Context
		correlationID string
		wantValue     string
	}{
		{
			name:          "nil with value",
			ctx:           nil,
			correlationID: "CORRELATION_ID",
			wantValue:     "CORRELATION_ID",
		},
		{
			name:          "nil with empty string",
			ctx:           nil,
			correlationID: "",
			wantValue:     "",
		},
		{
			name:          "value",
			ctx:           context.Background(),
			correlationID: "CORRELATION_ID",
			wantValue:     "CORRELATION_ID",
		},
		{
			name:          "empty",
			ctx:           context.Background(),
			correlationID: "",
			wantValue:     "",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := ContextWithCorrelation(tt.ctx, tt.correlationID)
			gotValue := got.Value(keyCorrelationID)
			if gotValue != tt.wantValue {
				t.Errorf("ContextWithCorrelation().Value() = %v, want %v", gotValue, tt.wantValue)
			}
		})
	}
}
