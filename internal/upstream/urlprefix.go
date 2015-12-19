package upstream

import (
	"strings"
)

type urlPrefix string

func (p urlPrefix) strip(path string) string {
	return cleanURIPath(strings.TrimPrefix(path, string(p)))
}

func (p urlPrefix) match(path string) bool {
	pre := string(p)
	return strings.HasPrefix(path, pre) || path+"/" == pre
}

func (u *Upstream) URLPrefix() urlPrefix {
	u.configureURLPrefixOnce.Do(u.configureURLPrefix)
	return u.urlPrefix
}

func (u *Upstream) configureURLPrefix() {
	if u.Backend == nil {
		u.Backend = DefaultBackend
	}
	relativeURLRoot := u.Backend.Path
	if !strings.HasSuffix(relativeURLRoot, "/") {
		relativeURLRoot += "/"
	}
	u.urlPrefix = urlPrefix(relativeURLRoot)
}
