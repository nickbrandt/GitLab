package testhelper

import (
	pb "gitlab.com/gitlab-org/gitaly-proto/go"
	"golang.org/x/net/context"
)

func (s *GitalyTestServer) RepositoryExists(context.Context, *pb.RepositoryExistsRequest) (*pb.RepositoryExistsResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) RepackIncremental(context.Context, *pb.RepackIncrementalRequest) (*pb.RepackIncrementalResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) RepackFull(context.Context, *pb.RepackFullRequest) (*pb.RepackFullResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) GarbageCollect(context.Context, *pb.GarbageCollectRequest) (*pb.GarbageCollectResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) RepositorySize(context.Context, *pb.RepositorySizeRequest) (*pb.RepositorySizeResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) ApplyGitattributes(context.Context, *pb.ApplyGitattributesRequest) (*pb.ApplyGitattributesResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) FetchRemote(context.Context, *pb.FetchRemoteRequest) (*pb.FetchRemoteResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) FetchSourceBranch(context.Context, *pb.FetchSourceBranchRequest) (*pb.FetchSourceBranchResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) CreateRepository(context.Context, *pb.CreateRepositoryRequest) (*pb.CreateRepositoryResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) Exists(context.Context, *pb.RepositoryExistsRequest) (*pb.RepositoryExistsResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) HasLocalBranches(ctx context.Context, in *pb.HasLocalBranchesRequest) (*pb.HasLocalBranchesResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) CommitDelta(in *pb.CommitDeltaRequest, stream pb.DiffService_CommitDeltaServer) error {
	return nil
}

func (s *GitalyTestServer) CommitDiff(in *pb.CommitDiffRequest, stream pb.DiffService_CommitDiffServer) error {
	return nil
}

func (s *GitalyTestServer) CommitPatch(in *pb.CommitPatchRequest, stream pb.DiffService_CommitPatchServer) error {
	return nil
}

func (s *GitalyTestServer) GetBlobs(in *pb.GetBlobsRequest, stream pb.BlobService_GetBlobsServer) error {
	return nil
}

func (s *GitalyTestServer) GetAllLFSPointers(*pb.GetAllLFSPointersRequest, pb.BlobService_GetAllLFSPointersServer) error {
	return nil
}

func (s *GitalyTestServer) GetLFSPointers(*pb.GetLFSPointersRequest, pb.BlobService_GetLFSPointersServer) error {
	return nil
}

func (s *GitalyTestServer) GetNewLFSPointers(*pb.GetNewLFSPointersRequest, pb.BlobService_GetNewLFSPointersServer) error {
	return nil
}

func (s *GitalyTestServer) CreateFork(context.Context, *pb.CreateForkRequest) (*pb.CreateForkResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) CalculateChecksum(context.Context, *pb.CalculateChecksumRequest) (*pb.CalculateChecksumResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) CreateBundle(*pb.CreateBundleRequest, pb.RepositoryService_CreateBundleServer) error {
	return nil
}

func (s *GitalyTestServer) CreateRepositoryFromBundle(pb.RepositoryService_CreateRepositoryFromBundleServer) error {
	return nil
}

func (s *GitalyTestServer) CreateRepositoryFromURL(context.Context, *pb.CreateRepositoryFromURLRequest) (*pb.CreateRepositoryFromURLResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) FindLicense(context.Context, *pb.FindLicenseRequest) (*pb.FindLicenseResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) FindMergeBase(context.Context, *pb.FindMergeBaseRequest) (*pb.FindMergeBaseResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) Fsck(context.Context, *pb.FsckRequest) (*pb.FsckResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) GetInfoAttributes(*pb.GetInfoAttributesRequest, pb.RepositoryService_GetInfoAttributesServer) error {
	return nil
}

func (s *GitalyTestServer) IsRebaseInProgress(context.Context, *pb.IsRebaseInProgressRequest) (*pb.IsRebaseInProgressResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) IsSquashInProgress(context.Context, *pb.IsSquashInProgressRequest) (*pb.IsSquashInProgressResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) WriteConfig(context.Context, *pb.WriteConfigRequest) (*pb.WriteConfigResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) WriteRef(context.Context, *pb.WriteRefRequest) (*pb.WriteRefResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) Cleanup(context.Context, *pb.CleanupRequest) (*pb.CleanupResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) CreateRepositoryFromSnapshot(context.Context, *pb.CreateRepositoryFromSnapshotRequest) (*pb.CreateRepositoryFromSnapshotResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) BackupCustomHooks(*pb.BackupCustomHooksRequest, pb.RepositoryService_BackupCustomHooksServer) error {
	return nil
}

func (s *GitalyTestServer) DeleteConfig(context.Context, *pb.DeleteConfigRequest) (*pb.DeleteConfigResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) GetRawChanges(*pb.GetRawChangesRequest, pb.RepositoryService_GetRawChangesServer) error {
	return nil
}

func (s *GitalyTestServer) RestoreCustomHooks(pb.RepositoryService_RestoreCustomHooksServer) error {
	return nil
}

func (s *GitalyTestServer) SearchFilesByContent(*pb.SearchFilesByContentRequest, pb.RepositoryService_SearchFilesByContentServer) error {
	return nil
}

func (s *GitalyTestServer) SearchFilesByName(*pb.SearchFilesByNameRequest, pb.RepositoryService_SearchFilesByNameServer) error {
	return nil
}

func (s *GitalyTestServer) SetConfig(context.Context, *pb.SetConfigRequest) (*pb.SetConfigResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) DiffStats(*pb.DiffStatsRequest, pb.DiffService_DiffStatsServer) error {
	return nil
}
