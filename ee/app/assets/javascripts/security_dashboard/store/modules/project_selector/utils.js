/**
 * Takes array of errors/successful responses and collects successfully added projects
 * and projects that resulted in an error into separate buckets
 * @param {Array} response returned from the server on an AddProject mutation
 * @param {Array} selectedProjects all projects meant to be added
 */

export const processAddProjectResponse = (response, selectedProjects) => {
  return response.reduce(
    (acc, curr, i) => {
      const project = curr?.data.addProjectToSecurityDashboard.project;

      if (project) {
        acc.added.push(project);
      } else {
        acc.invalid.push(selectedProjects[i].id);
      }

      return acc;
    },
    { added: [], invalid: [] },
  );
};

export default {};
