export default () => ({
  inputValue: '',
  isLoadingProjects: false,
  isAddingProjects: false,
  isRemovingProject: false,
  searchQuery: '',
  projects: [],
  projectSearchResults: [],
  selectedProjects: [],
  messages: {
    noResults: false,
    searchError: false,
    minimumQuery: false,
  },
  searchCount: 0,
  pageInfo: {
    endCursor: '',
    hasNextPage: true,
  },
});
