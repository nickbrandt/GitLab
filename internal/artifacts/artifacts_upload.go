package artifacts

import (
	"../api"
	"../helper"
	"../upload"
	"errors"
	"fmt"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"os"
)

// The artifactsFormFilter allows to pass only the `file` as file in body
type artifactsUploadProcessor struct {
	TempPath     string
	metadataFile string
}

func (a *artifactsUploadProcessor) ProcessFile(formName, fileName string, writer *multipart.Writer) error {
	if formName != "file" {
		return fmt.Errorf("Invalid form field: %q", formName)
	}
	if a.metadataFile != "" {
		return fmt.Errorf("Multiple files")
	}

	// Create temporary file for metadata and store it's path
	tempFile, err := ioutil.TempFile(a.TempPath, "metadata_")
	if err != nil {
		return err
	}
	defer tempFile.Close()
	a.metadataFile = tempFile.Name()

	// Generate metadata and save to file
	err = generateZipMetadataFromFile(fileName, tempFile)
	if err == os.ErrInvalid {
		return nil
	} else if err != nil {
		return err
	}

	// Pass metadata file path to Rails
	writer.WriteField("metadata.path", a.metadataFile)
	writer.WriteField("metadata.name", "metadata.gz")
	return nil
}

func (a *artifactsUploadProcessor) ProcessField(formName string, writer *multipart.Writer) error {
	return nil
}

func (a *artifactsUploadProcessor) Cleanup() {
	if a.metadataFile != "" {
		os.Remove(a.metadataFile)
	}
}

func UploadArtifacts(myAPI *api.API, h http.Handler) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		if a.TempPath == "" {
			helper.Fail500(w, errors.New("UploadArtifacts: TempPath is empty"))
			return
		}

		mg := &artifactsUploadProcessor{TempPath: a.TempPath}
		defer mg.Cleanup()

		upload.HandleFileUploads(w, r, h, a.TempPath, mg)
	}, "/authorize")
}
