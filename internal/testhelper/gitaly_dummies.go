package testhelper

import (
	"gitlab.com/gitlab-org/gitaly-proto/go/gitalypb"
	"golang.org/x/net/context"
)

func (s *GitalyTestServer) RepositoryExists(context.Context, *gitalypb.RepositoryExistsRequest) (*gitalypb.RepositoryExistsResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) RepackIncremental(context.Context, *gitalypb.RepackIncrementalRequest) (*gitalypb.RepackIncrementalResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) RepackFull(context.Context, *gitalypb.RepackFullRequest) (*gitalypb.RepackFullResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) GarbageCollect(context.Context, *gitalypb.GarbageCollectRequest) (*gitalypb.GarbageCollectResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) RepositorySize(context.Context, *gitalypb.RepositorySizeRequest) (*gitalypb.RepositorySizeResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) ApplyGitattributes(context.Context, *gitalypb.ApplyGitattributesRequest) (*gitalypb.ApplyGitattributesResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) FetchRemote(context.Context, *gitalypb.FetchRemoteRequest) (*gitalypb.FetchRemoteResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) FetchSourceBranch(context.Context, *gitalypb.FetchSourceBranchRequest) (*gitalypb.FetchSourceBranchResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) CreateRepository(context.Context, *gitalypb.CreateRepositoryRequest) (*gitalypb.CreateRepositoryResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) Exists(context.Context, *gitalypb.RepositoryExistsRequest) (*gitalypb.RepositoryExistsResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) HasLocalBranches(ctx context.Context, in *gitalypb.HasLocalBranchesRequest) (*gitalypb.HasLocalBranchesResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) CommitDelta(in *gitalypb.CommitDeltaRequest, stream gitalypb.DiffService_CommitDeltaServer) error {
	return nil
}

func (s *GitalyTestServer) CommitDiff(in *gitalypb.CommitDiffRequest, stream gitalypb.DiffService_CommitDiffServer) error {
	return nil
}

func (s *GitalyTestServer) CommitPatch(in *gitalypb.CommitPatchRequest, stream gitalypb.DiffService_CommitPatchServer) error {
	return nil
}

func (s *GitalyTestServer) GetBlobs(in *gitalypb.GetBlobsRequest, stream gitalypb.BlobService_GetBlobsServer) error {
	return nil
}

func (s *GitalyTestServer) GetAllLFSPointers(*gitalypb.GetAllLFSPointersRequest, gitalypb.BlobService_GetAllLFSPointersServer) error {
	return nil
}

func (s *GitalyTestServer) GetLFSPointers(*gitalypb.GetLFSPointersRequest, gitalypb.BlobService_GetLFSPointersServer) error {
	return nil
}

func (s *GitalyTestServer) GetNewLFSPointers(*gitalypb.GetNewLFSPointersRequest, gitalypb.BlobService_GetNewLFSPointersServer) error {
	return nil
}

func (s *GitalyTestServer) CreateFork(context.Context, *gitalypb.CreateForkRequest) (*gitalypb.CreateForkResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) CalculateChecksum(context.Context, *gitalypb.CalculateChecksumRequest) (*gitalypb.CalculateChecksumResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) CreateBundle(*gitalypb.CreateBundleRequest, gitalypb.RepositoryService_CreateBundleServer) error {
	return nil
}

func (s *GitalyTestServer) CreateRepositoryFromBundle(gitalypb.RepositoryService_CreateRepositoryFromBundleServer) error {
	return nil
}

func (s *GitalyTestServer) CreateRepositoryFromURL(context.Context, *gitalypb.CreateRepositoryFromURLRequest) (*gitalypb.CreateRepositoryFromURLResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) FindLicense(context.Context, *gitalypb.FindLicenseRequest) (*gitalypb.FindLicenseResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) FindMergeBase(context.Context, *gitalypb.FindMergeBaseRequest) (*gitalypb.FindMergeBaseResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) Fsck(context.Context, *gitalypb.FsckRequest) (*gitalypb.FsckResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) GetInfoAttributes(*gitalypb.GetInfoAttributesRequest, gitalypb.RepositoryService_GetInfoAttributesServer) error {
	return nil
}

func (s *GitalyTestServer) IsRebaseInProgress(context.Context, *gitalypb.IsRebaseInProgressRequest) (*gitalypb.IsRebaseInProgressResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) IsSquashInProgress(context.Context, *gitalypb.IsSquashInProgressRequest) (*gitalypb.IsSquashInProgressResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) WriteConfig(context.Context, *gitalypb.WriteConfigRequest) (*gitalypb.WriteConfigResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) WriteRef(context.Context, *gitalypb.WriteRefRequest) (*gitalypb.WriteRefResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) Cleanup(context.Context, *gitalypb.CleanupRequest) (*gitalypb.CleanupResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) CreateRepositoryFromSnapshot(context.Context, *gitalypb.CreateRepositoryFromSnapshotRequest) (*gitalypb.CreateRepositoryFromSnapshotResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) BackupCustomHooks(*gitalypb.BackupCustomHooksRequest, gitalypb.RepositoryService_BackupCustomHooksServer) error {
	return nil
}

func (s *GitalyTestServer) DeleteConfig(context.Context, *gitalypb.DeleteConfigRequest) (*gitalypb.DeleteConfigResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) GetRawChanges(*gitalypb.GetRawChangesRequest, gitalypb.RepositoryService_GetRawChangesServer) error {
	return nil
}

func (s *GitalyTestServer) RestoreCustomHooks(gitalypb.RepositoryService_RestoreCustomHooksServer) error {
	return nil
}

func (s *GitalyTestServer) SearchFilesByContent(*gitalypb.SearchFilesByContentRequest, gitalypb.RepositoryService_SearchFilesByContentServer) error {
	return nil
}

func (s *GitalyTestServer) SearchFilesByName(*gitalypb.SearchFilesByNameRequest, gitalypb.RepositoryService_SearchFilesByNameServer) error {
	return nil
}

func (s *GitalyTestServer) SetConfig(context.Context, *gitalypb.SetConfigRequest) (*gitalypb.SetConfigResponse, error) {
	return nil, nil
}

func (s *GitalyTestServer) DiffStats(*gitalypb.DiffStatsRequest, gitalypb.DiffService_DiffStatsServer) error {
	return nil
}
