// eslint-disable-next-line import/prefer-default-export
export const parseFeatureFlagsParams = params => ({
  operations_feature_flag: {
    name: params.name,
    description: params.description,
    // removes uniqueId key used in creation form
    scopes_attributes: params.scopes.map(scope => {
      const scopeCopy = Object.assign({}, scope);
      delete scopeCopy.uniqueId;
      return scopeCopy;
    }),
  },
});
