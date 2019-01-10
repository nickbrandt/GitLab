package gitaly

import (
	"sync"

	grpc_middleware "github.com/grpc-ecosystem/go-grpc-middleware"
	grpc_prometheus "github.com/grpc-ecosystem/go-grpc-prometheus"
	"gitlab.com/gitlab-org/gitaly-proto/go/gitalypb"
	gitalyauth "gitlab.com/gitlab-org/gitaly/auth"
	gitalyclient "gitlab.com/gitlab-org/gitaly/client"
	"google.golang.org/grpc"

	grpccorrelation "gitlab.com/gitlab-org/labkit/correlation/grpc"
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
	grpcClient := gitalypb.NewSmartHTTPServiceClient(conn)
	return &SmartHTTPClient{grpcClient}, nil
}

func NewBlobClient(server Server) (*BlobClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, err
	}
	grpcClient := gitalypb.NewBlobServiceClient(conn)
	return &BlobClient{grpcClient}, nil
}

func NewRepositoryClient(server Server) (*RepositoryClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, err
	}
	grpcClient := gitalypb.NewRepositoryServiceClient(conn)
	return &RepositoryClient{grpcClient}, nil
}

// NewNamespaceClient is only used by the Gitaly integration tests at present
func NewNamespaceClient(server Server) (*NamespaceClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, err
	}
	grpcClient := gitalypb.NewNamespaceServiceClient(conn)
	return &NamespaceClient{grpcClient}, nil
}

func NewDiffClient(server Server) (*DiffClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, err
	}
	grpcClient := gitalypb.NewDiffServiceClient(conn)
	return &DiffClient{grpcClient}, nil
}

func getOrCreateConnection(server Server) (*grpc.ClientConn, error) {
	cache.RLock()
	conn := cache.connections[server]
	cache.RUnlock()

	if conn != nil {
		return conn, nil
	}

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
	connOpts := append(gitalyclient.DefaultDialOpts,
		grpc.WithPerRPCCredentials(gitalyauth.RPCCredentialsV2(server.Token)),
		grpc.WithStreamInterceptor(
			grpc_middleware.ChainStreamClient(
				grpc_prometheus.StreamClientInterceptor,
				grpccorrelation.StreamClientCorrelationInterceptor(),
			),
		),

		grpc.WithUnaryInterceptor(
			grpc_middleware.ChainUnaryClient(
				grpc_prometheus.UnaryClientInterceptor,
				grpccorrelation.UnaryClientCorrelationInterceptor(),
			),
		),
	)

	return gitalyclient.Dial(server.Address, connOpts)
}
