package parser

import (
	"fmt"
	"os"
	"runtime"
	"testing"

	"github.com/stretchr/testify/require"
)

func BenchmarkGenerate(b *testing.B) {
	filePath := "testdata/workhorse.lsif.zip"
	tmpDir := filePath + ".tmp"
	defer os.RemoveAll(tmpDir)

	m := measureMemory(func() {
		file, err := os.Open(filePath)
		require.NoError(b, err)

		p, err := NewParser(file, "")
		require.NoError(b, err)

		_, err = p.ZipReader()
		require.NoError(b, err)
		require.NoError(b, p.Close())
	})

	// Golang 1.13 has `func (*B) ReportMetric`
	// It makes sense to replace fmt.Printf with
	// b.ReportMetric(m, "MiB/op")

	fmt.Printf("BenchmarkGenerate: %f MiB/op\n", m)
}

func measureMemory(f func()) float64 {
	var m, m1 runtime.MemStats
	runtime.ReadMemStats(&m)

	f()

	runtime.ReadMemStats(&m1)

	return float64(m1.Alloc-m.Alloc) / 1024 / 1024
}
