import _ from 'underscore';

export const internalKeyID = 'internal_';

export const parseFeatureFlagsParams = params => ({
  operations_feature_flag: {
    name: params.name,
    description: params.description,
    scopes_attributes: params.scopes.map(scope => {
      const scopeCopy = Object.assign({}, scope);
      if (_.isString(scopeCopy.id) && scopeCopy.id.indexOf(internalKeyID) !== -1) {
        delete scopeCopy.id;
      }
      return scopeCopy;
    }),
  },
});
