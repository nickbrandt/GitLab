package senddata

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
)

type Injecter interface {
	Match(string) bool
	Inject(http.ResponseWriter, *http.Request, string)
}

type Prefix string

const Header = "Gitlab-Workhorse-Send-Data"

func (p Prefix) Match(s string) bool {
	return strings.HasPrefix(s, string(p))
}

func (p Prefix) Unpack(result interface{}, sendData string) error {
	jsonBytes, err := base64.URLEncoding.DecodeString(strings.TrimPrefix(sendData, string(p)))
	if err != nil {
		return err
	}
	if err := json.Unmarshal([]byte(jsonBytes), result); err != nil {
		return err
	}
	return nil
}
