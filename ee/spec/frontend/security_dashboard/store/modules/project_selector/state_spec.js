import createState from 'ee/security_dashboard/store/modules/project_selector/state';

describe('projectsSelector default state', () => {
  const state = createState();

  it('has "inputValue" set to be an empty string', () => {
    expect(state.inputValue).toBe('');
  });

  it('has "isLoadingProjects" set to be false', () => {
    expect(state.isLoadingProjects).toBe(false);
  });

  it('has "isAddingProjects" set to be false', () => {
    expect(state.isAddingProjects).toBe(false);
  });

  it('has "isRemovingProject" set to be false', () => {
    expect(state.isRemovingProject).toBe(false);
  });

  it('has all "projectEndpoints" set to be null', () => {
    expect(state.projectEndpoints.list).toBe(null);
    expect(state.projectEndpoints.add).toBe(null);
  });

  it('has "searchQuery" set to an empty string', () => {
    expect(state.searchQuery).toBe('');
  });

  it('has "projects" set to be an empty array', () => {
    expect(state.projects).toEqual([]);
  });

  it('has "projectSearchResults" set to be an empty array', () => {
    expect(state.projectSearchResults).toEqual([]);
  });

  it('has "selectedProjects" set to be an empty array', () => {
    expect(state.selectedProjects).toEqual([]);
  });

  it('has all "messages" set to be false', () => {
    expect(state.messages.noResults).toBe(false);
    expect(state.messages.searchError).toBe(false);
    expect(state.messages.minimumQuery).toBe(false);
  });

  it('has "searchCount" set to be 0', () => {
    expect(state.searchCount).toBe(0);
  });
});
