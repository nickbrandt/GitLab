package config

import (
	"net/url"
	"time"
)

type Config struct {
	Backend             *url.URL
	Version             string
	DocumentRoot        string
	DevelopmentMode     bool
	Socket              string
	ProxyHeadersTimeout time.Duration
	APILimit            uint
	APIQueueLimit       uint
	APIQueueTimeout     time.Duration
}
