package config

import (
	"net/url"
	"time"

	"github.com/BurntSushi/toml"
)

type TomlURL struct {
	url.URL
}

func (u *TomlURL) UnmarshalText(text []byte) error {
	temp, err := url.Parse(string(text))
	u.URL = *temp
	return err
}

type TomlDuration struct {
	time.Duration
}

func (d *TomlDuration) UnmarshalTest(text []byte) error {
	temp, err := time.ParseDuration(string(text))
	d.Duration = temp
	return err
}

type ObjectStorageCredentials struct {
	Provider string

	S3Credentials S3Credentials `toml:"s3"`
}

type S3Credentials struct {
	AwsAccessKeyID     string `toml:"aws_access_key_id"`
	AwsSecretAccessKey string `toml:"aws_secret_access_key"`
}

type S3Config struct {
	Region               string `toml:"-"`
	Bucket               string `toml:"-"`
	PathStyle            bool   `toml:"-"`
	Endpoint             string `toml:"-"`
	UseIamProfile        bool   `toml:"-"`
	ServerSideEncryption string `toml:"-"` // Server-side encryption mode (e.g. AES256, aws:kms)
	SSEKMSKeyID          string `toml:"-"` // Server-side encryption key-management service key ID (e.g. arn:aws:xxx)
}

type RedisConfig struct {
	URL             TomlURL
	Sentinel        []TomlURL
	SentinelMaster  string
	Password        string
	DB              *int
	ReadTimeout     *TomlDuration
	WriteTimeout    *TomlDuration
	KeepAlivePeriod *TomlDuration
	MaxIdle         *int
	MaxActive       *int
}

type Config struct {
	Redis                    *RedisConfig              `toml:"redis"`
	Backend                  *url.URL                  `toml:"-"`
	CableBackend             *url.URL                  `toml:"-"`
	Version                  string                    `toml:"-"`
	DocumentRoot             string                    `toml:"-"`
	DevelopmentMode          bool                      `toml:"-"`
	Socket                   string                    `toml:"-"`
	CableSocket              string                    `toml:"-"`
	ProxyHeadersTimeout      time.Duration             `toml:"-"`
	APILimit                 uint                      `toml:"-"`
	APIQueueLimit            uint                      `toml:"-"`
	APIQueueTimeout          time.Duration             `toml:"-"`
	APICILongPollingDuration time.Duration             `toml:"-"`
	ObjectStorageCredentials *ObjectStorageCredentials `toml:"object_storage"`
}

// LoadConfig from a file
func LoadConfig(filename string) (*Config, error) {
	cfg := &Config{}
	if _, err := toml.DecodeFile(filename, cfg); err != nil {
		return nil, err
	}

	return cfg, nil
}
