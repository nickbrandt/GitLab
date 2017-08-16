package gitaly

import (
	"fmt"
	"net"
	"net/url"
	"strings"
	"sync"
	"time"

	pb "gitlab.com/gitlab-org/gitaly-proto/go"
	"gitlab.com/gitlab-org/gitaly/auth"
	"google.golang.org/grpc"
)

type Server struct {
	Address string `json:"address"`
	Token   string `json:"token"`
}

type connectionsCache struct {
	sync.RWMutex
	connections map[Server]*grpc.ClientConn
}

var cache = connectionsCache{
	connections: make(map[Server]*grpc.ClientConn),
}

func NewSmartHTTPClient(server Server) (*SmartHTTPClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, err
	}
	grpcClient := pb.NewSmartHTTPServiceClient(conn)
	return &SmartHTTPClient{grpcClient}, nil
}

func NewBlobClient(server Server) (*BlobClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, err
	}
	grpcClient := pb.NewBlobServiceClient(conn)
	return &BlobClient{grpcClient}, nil
}

func getOrCreateConnection(server Server) (*grpc.ClientConn, error) {
	cache.Lock()
	defer cache.Unlock()

	if conn := cache.connections[server]; conn != nil {
		return conn, nil
	}

	conn, err := newConnection(server)
	if err != nil {
		return nil, err
	}

	cache.connections[server] = conn

	return conn, nil
}

func CloseConnections() {
	cache.Lock()
	defer cache.Unlock()

	for _, conn := range cache.connections {
		conn.Close()
	}
}

func newConnection(server Server) (*grpc.ClientConn, error) {
	network, addr, err := parseAddress(server.Address)
	if err != nil {
		return nil, err
	}

	connOpts := []grpc.DialOption{
		grpc.WithInsecure(), // Since we're connecting to Gitaly over UNIX, we don't need to use TLS credentials.
		grpc.WithDialer(func(a string, _ time.Duration) (net.Conn, error) {
			return net.Dial(network, a)
		}),
		grpc.WithPerRPCCredentials(gitalyauth.RPCCredentials(server.Token)),
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
