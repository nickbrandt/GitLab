export default () => ({
  inputValue: '',
  isLoadingProjects: false,
  projectEndpoints: {
    list: null,
    add: null,
  },
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
});
