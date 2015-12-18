package main

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
