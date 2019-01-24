// eslint-disable-next-line import/prefer-default-export
export const parseFeatureFlagsParams = params => ({
  operations_feature_flags: {
    name: params.name,
    description: params.description,
    active: true,
    scopes_attributes: params.scopes.map(scope => ({
      environment_scope: scope.name,
      active: scope.active,
    })),
  },
});
