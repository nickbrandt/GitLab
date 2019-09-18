export const getLabelsEndpoint = (namespacePath, projectPathWithNamespace) => {
  if (projectPathWithNamespace) {
    return `/${projectPathWithNamespace}/-/labels`;
  }

  return `/groups/${namespacePath}/-/labels`;
};

export const getMilestonesEndpoint = (namespacePath, projectPathWithNamespace) => {
  if (projectPathWithNamespace) {
    return `/${projectPathWithNamespace}/-/milestones`;
  }

  return `/groups/${namespacePath}/-/milestones`;
};
