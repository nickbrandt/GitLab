import { property } from 'lodash';

export const ROLLOUT_STRATEGY_ALL_USERS = 'default';
export const ROLLOUT_STRATEGY_PERCENT_ROLLOUT = 'gradualRolloutUserId';
export const ROLLOUT_STRATEGY_USER_ID = 'userWithId';

export const PERCENT_ROLLOUT_GROUP_ID = 'default';

export const DEFAULT_PERCENT_ROLLOUT = '100';

export const ALL_ENVIRONMENTS_NAME = '*';

export const INTERNAL_ID_PREFIX = 'internal_';

export const fetchPercentageParams = property(['parameters', 'percentage']);
export const fetchUserIdParams = property(['parameters', 'userIds']);

export const NEW_VERSION_FLAG = 'new_version_flag';
export const LEGACY_FLAG = 'legacy_flag';
