package gitaly

import (
	"fmt"
	"net"
	"net/url"
	"strings"
	"sync"
	"time"

	pb "gitlab.com/gitlab-org/gitaly-proto/go"
	"google.golang.org/grpc"
)

type Server struct {
	Address string `json:"address"`
	Token   string `json:"token"`
}

type connectionsCache struct {
	sync.RWMutex
	connections map[string]*grpc.ClientConn
}

var cache = connectionsCache{
	connections: make(map[string]*grpc.ClientConn),
}

func NewSmartHTTPClient(server Server) (*SmartHTTPClient, error) {
	conn, err := getOrCreateConnection(server.Address)
	if err != nil {
		return nil, err
	}
	grpcClient := pb.NewSmartHTTPClient(conn)
	return &SmartHTTPClient{grpcClient}, nil
}

func getOrCreateConnection(address string) (*grpc.ClientConn, error) {
	cache.Lock()
	defer cache.Unlock()

	if conn := cache.connections[address]; conn != nil {
		return conn, nil
	}

	conn, err := newConnection(address)
	if err != nil {
		return nil, err
	}

	cache.connections[address] = conn

	return conn, nil
}

func CloseConnections() {
	cache.Lock()
	defer cache.Unlock()

	for _, conn := range cache.connections {
		conn.Close()
	}
}

func newConnection(rawAddress string) (*grpc.ClientConn, error) {
	network, addr, err := parseAddress(rawAddress)
	if err != nil {
		return nil, err
	}

	connOpts := []grpc.DialOption{
		grpc.WithInsecure(), // Since we're connecting to Gitaly over UNIX, we don't need to use TLS credentials.
		grpc.WithDialer(func(a string, _ time.Duration) (net.Conn, error) {
			return net.Dial(network, a)
		}),
	}
	conn, err := grpc.Dial(addr, connOpts...)
	if err != nil {
		return nil, err
	}

	return conn, nil
}

func parseAddress(rawAddress string) (network, addr string, err error) {
	// Parsing unix:// URL's with url.Parse does not give the result we want
	// so we do it manually.
	for _, prefix := range []string{"unix://", "unix:"} {
		if strings.HasPrefix(rawAddress, prefix) {
			return "unix", strings.TrimPrefix(rawAddress, prefix), nil
		}
	}

	u, err := url.Parse(rawAddress)
	if err != nil {
		return "", "", err
	}

	if u.Scheme != "tcp" {
		return "", "", fmt.Errorf("unknown scheme: %q", rawAddress)
	}
	if u.Host == "" {
		return "", "", fmt.Errorf("network tcp requires host: %q", rawAddress)
	}
	if u.Path != "" {
		return "", "", fmt.Errorf("network tcp should have no path: %q", rawAddress)
	}
	return "tcp", u.Host, nil
}
