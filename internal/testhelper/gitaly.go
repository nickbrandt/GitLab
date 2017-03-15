package testhelper

import (
	"io"
	"io/ioutil"
	"log"
	"path"

	pb "gitlab.com/gitlab-org/gitaly-proto/go"
)

type GitalyTestServer struct{}

const GitalyInfoRefsResponseMock = "Mock Gitaly InfoRefsResponse data"

var GitalyReceivePackResponseMock []byte
var GitalyUploadPackResponseMock []byte

func init() {
	var err error
	if GitalyReceivePackResponseMock, err = ioutil.ReadFile(path.Join(RootDir(), "testdata/receive-pack-fixture.txt")); err != nil {
		log.Fatal(err)
	}
	if GitalyUploadPackResponseMock, err = ioutil.ReadFile(path.Join(RootDir(), "testdata/upload-pack-fixture.txt")); err != nil {
		log.Fatal(err)
	}
}

func NewGitalyServer() *GitalyTestServer {
	return &GitalyTestServer{}
}

func (s *GitalyTestServer) InfoRefsUploadPack(in *pb.InfoRefsRequest, stream pb.SmartHTTP_InfoRefsUploadPackServer) error {
	response := &pb.InfoRefsResponse{
		Data: []byte(GitalyInfoRefsResponseMock),
	}
	return stream.Send(response)
}

func (s *GitalyTestServer) InfoRefsReceivePack(in *pb.InfoRefsRequest, stream pb.SmartHTTP_InfoRefsReceivePackServer) error {
	response := &pb.InfoRefsResponse{
		Data: []byte(GitalyInfoRefsResponseMock),
	}
	return stream.Send(response)
}

func (s *GitalyTestServer) PostReceivePack(stream pb.SmartHTTP_PostReceivePackServer) error {
	req, err := stream.Recv()
	if err != nil {
		return err
	}

	response := &pb.PostReceivePackResponse{
		Data: []byte(req.Repository.GetPath() + req.GlId),
	}
	if err := stream.Send(response); err != nil {
		return err
	}

	// The body of the request starts in the second message
	for {
		req, err := stream.Recv()
		if err != nil {
			if err != io.EOF {
				return err
			}
			break
		}

		response := &pb.PostReceivePackResponse{
			Data: req.GetData(),
		}
		if err := stream.Send(response); err != nil {
			return err
		}
	}

	return nil
}

func (s *GitalyTestServer) PostUploadPack(stream pb.SmartHTTP_PostUploadPackServer) error {
	req, err := stream.Recv()
	if err != nil {
		return err
	}

	response := &pb.PostUploadPackResponse{
		Data: []byte(req.Repository.GetPath()),
	}
	if err := stream.Send(response); err != nil {
		return err
	}

	// The body of the request starts in the second message
	for {
		req, err := stream.Recv()
		if err != nil {
			if err != io.EOF {
				return err
			}
			break
		}

		response := &pb.PostUploadPackResponse{
			Data: req.GetData(),
		}
		if err := stream.Send(response); err != nil {
			return err
		}
	}

	return nil
}
