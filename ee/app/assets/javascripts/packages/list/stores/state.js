export default () => ({
  isLoading: false,
  /** project id used to fetch data */
  projectId: null,
  userCanDelete: false, // controls the delete buttons in the list
  /**
   * Each object in `packages` has the following structure:
   * {
   *   id: String
   *   name: String,
   *   version: String,
   *   package_type: String // endpoint to request the list
   * }
   */
  packages: [],
  pagination: {},
});
