package artifacts

import (
	"log"
	"os"
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
)

func TestMain(m *testing.M) {
	cleanup, err := testhelper.BuildExecutables()
	if err != nil {
		log.Printf("Test setup: failed to build executables: %v", err)
		os.Exit(1)
	}

	os.Exit(func() int {
		defer cleanup()
		return m.Run()
	}())

}
