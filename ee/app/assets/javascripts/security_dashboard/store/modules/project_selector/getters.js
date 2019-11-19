export const canAddProjects = ({ isAddingProjects, selectedProjects }) =>
  !isAddingProjects && selectedProjects.length > 0;

export const isSearchingProjects = ({ searchCount }) => searchCount > 0;

export const isUpdatingProjects = ({ isAddingProjects, isLoadingProjects, isRemovingProject }) =>
  isAddingProjects || isLoadingProjects || isRemovingProject;
