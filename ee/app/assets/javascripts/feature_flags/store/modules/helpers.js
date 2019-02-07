// eslint-disable-next-line import/prefer-default-export
export const parseFeatureFlagsParams = params => ({
  operations_feature_flag: {
    name: params.name,
    description: params.description,
    scopes_attributes: params.scopes,
  },
});
