import _ from 'underscore';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  INTERNAL_ID_PREFIX,
  DEFAULT_PERCENT_ROLLOUT,
  PERCENT_ROLLOUT_GROUP_ID,
} from '../../constants';

/**
 * Converts raw scope objects fetched from the API into an array of scope
 * objects that is easier/nicer to bind to in Vue.
 * @param {Array} scopesFromRails An array of scope objects fetched from the API
 */
export const mapToScopesViewModel = scopesFromRails =>
  (scopesFromRails || []).map(s => {
    const [strategy] = s.strategies || [];

    const rolloutStrategy = strategy ? strategy.name : ROLLOUT_STRATEGY_ALL_USERS;

    let rolloutPercentage = DEFAULT_PERCENT_ROLLOUT;
    if (strategy && strategy.parameters && strategy.parameters.percentage) {
      rolloutPercentage = strategy.parameters.percentage;
    }

    return {
      id: s.id,
      environmentScope: s.environment_scope,
      active: Boolean(s.active),
      canUpdate: Boolean(s.can_update),
      protected: Boolean(s.protected),
      rolloutStrategy,
      rolloutPercentage,

      // eslint-disable-next-line no-underscore-dangle
      shouldBeDestroyed: Boolean(s._destroy),
    };
  });

/**
 * Converts the parameters emitted by the Vue component into
 * the shape that the Rails API expects.
 * @param {Array} scopesFromVue An array of scope objects from the Vue component
 */
export const mapFromScopesViewModel = params => {
  const scopes = (params.scopes || []).map(s => {
    const parameters = {};
    if (s.rolloutStrategy === ROLLOUT_STRATEGY_PERCENT_ROLLOUT) {
      parameters.groupId = PERCENT_ROLLOUT_GROUP_ID;
      parameters.percentage = s.rolloutPercentage;
    }

    // Strip out any internal IDs
    const id = _.isString(s.id) && s.id.startsWith(INTERNAL_ID_PREFIX) ? undefined : s.id;

    return {
      id,
      environment_scope: s.environmentScope,
      active: s.active,
      can_update: s.canUpdate,
      protected: s.protected,
      _destroy: s.shouldBeDestroyed,
      strategies: [
        {
          name: s.rolloutStrategy,
          parameters,
        },
      ],
    };
  });

  return {
    operations_feature_flag: {
      name: params.name,
      description: params.description,
      scopes_attributes: scopes,
    },
  };
};

/**
 * Creates a new feature flag environment scope object for use
 * in a Vue component.  An optional parameter can be passed to
 * override the property values that are created by default.
 *
 * @param {Object} overrides An optional object whose
 * property values will be used to override the default values.
 *
 */
export const createNewEnvironmentScope = (overrides = {}) => {
  const defaultScope = {
    environmentScope: '',
    active: false,
    id: _.uniqueId(INTERNAL_ID_PREFIX),
    rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
    rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
  };

  const newScope = {
    ...defaultScope,
    ...overrides,
  };

  if (gon && gon.features && gon.features.featureFlagPermissions) {
    newScope.canUpdate = true;
    newScope.protected = false;
  }

  return newScope;
};
