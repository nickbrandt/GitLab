package objectstore

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/xml"
	"fmt"
)

// CompleteMultipartUpload is the S3 CompleteMultipartUpload body
type CompleteMultipartUpload struct {
	Part []*completeMultipartUploadPart
}

type completeMultipartUploadPart struct {
	PartNumber int
	ETag       string
}

// CompleteMultipartUploadResult is the S3 answer to CompleteMultipartUpload request
type CompleteMultipartUploadResult struct {
	Location string
	Bucket   string
	Key      string
	ETag     string
}

// CompleteMultipartUploadError is the in-body error structure
// https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadComplete.html#mpUploadComplete-examples
// the answer contains other fields we are not using
type CompleteMultipartUploadError struct {
	XMLName xml.Name `xml:"Error"`
	Code    string
	Message string
}

func (c *CompleteMultipartUploadError) Error() string {
	return fmt.Sprintf("CompleteMultipartUpload remote error %q: %s", c.Code, c.Message)
}

// compoundCompleteMultipartUploadResult holds both CompleteMultipartUploadResult and CompleteMultipartUploadError
// this allow us to deserialize the response body where the root element can either be Error orCompleteMultipartUploadResult
type compoundCompleteMultipartUploadResult struct {
	*CompleteMultipartUploadResult
	*CompleteMultipartUploadError

	// XMLName this overrides CompleteMultipartUploadError.XMLName tags
	XMLName xml.Name
}

func (c *compoundCompleteMultipartUploadResult) isError() bool {
	return c.CompleteMultipartUploadError != nil
}

// BuildMultipartUploadETag creates an S3 compatible ETag for MultipartUpload
// Given the MD5 hash for each uploaded part of the file, concatenate
// the hashes into a single binary string and calculate the MD5 hash of that result,
// the append "-len(etags)"
// http://permalink.gmane.org/gmane.comp.file-systems.s3.s3tools/583
func (cmu *CompleteMultipartUpload) BuildMultipartUploadETag() (string, error) {
	hasher := md5.New()
	for _, part := range cmu.Part {
		checksum, err := hex.DecodeString(part.ETag)
		if err != nil {
			return "", err
		}
		_, err = hasher.Write(checksum)
		if err != nil {
			return "", err
		}
	}

	multipartChecksum := hasher.Sum(nil)
	return fmt.Sprintf("%s-%d", hex.EncodeToString(multipartChecksum), len(cmu.Part)), nil
}
