package gitaly

import (
	"sync"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/badgateway"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/proxy"
)

type Client struct {
	Proxy *proxy.Proxy
}

type clientCache struct {
	sync.RWMutex
	clients map[string]*Client
}

var cache = clientCache{
	clients: make(map[string]*Client),
}

func NewClient(socketPath string, cfg *config.Config) *Client {
	if client := getClient(socketPath); client != nil {
		return client
	}

	cache.Lock()
	defer cache.Unlock()

	if client := cache.clients[socketPath]; client != nil {
		return client
	}

	client := &Client{}
	roundTripper := badgateway.NewRoundTripper(nil, socketPath, cfg.ProxyHeadersTimeout, cfg.DevelopmentMode)
	client.Proxy = proxy.NewProxy(nil, cfg.Version, roundTripper)
	client.Proxy.AllowResponseBuffering = false

	cache.clients[socketPath] = client

	return client
}

func getClient(socketPath string) *Client {
	cache.RLock()
	defer cache.RUnlock()

	return cache.clients[socketPath]
}
