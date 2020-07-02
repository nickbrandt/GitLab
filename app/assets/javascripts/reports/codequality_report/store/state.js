export default (initialState = {}) => ({
  basePath: initialState.basePath || '',
  headPath: initialState.headPath || '',

  baseBlobPath: initialState.baseBlobPath || '',
  headBlobPath: initialState.headBlobPath || '',

  isLoading: initialState.isLoading || false,
  hasError: initialState.hasError || false,

  newIssues: initialState.newIssues || [],
  resolvedIssues: initialState.resolvedIssues || [],

  helpPath: initialState.helpPath || '',
});
