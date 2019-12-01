export default () => ({
  /**
   * Determine if the component is loading data from the API
   */
  isLoading: false,
  /**
   * configuration object, set once at store creation with the following structure
   * {
   *  resourceId: String,
   *  pageType: String,
   *  userCanDelete: Boolean,
   *  emptyListIllustration: String,
   *  emptyListHelpUrl: String
   * }
   */
  config: {},
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
  /**
   * Pagination object has the following structure:
   * {
   *  perPage: Number,
   *  page: Number
   *  total: Number
   * }
   */
  pagination: {},
});
