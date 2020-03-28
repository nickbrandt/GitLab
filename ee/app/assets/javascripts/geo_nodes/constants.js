export const NODE_ACTIONS = {
  TOGGLE: 'toggle',
  REMOVE: 'remove',
};

export const VALUE_TYPE = {
  PLAIN: 'plain',
  GRAPH: 'graph',
  CUSTOM: 'custom',
};

export const CUSTOM_TYPE = {
  SYNC: 'sync',
  EVENT: 'event',
  STATUS: 'status',
};

export const HEALTH_STATUS_ICON = {
  healthy: 'status_success',
  unhealthy: 'status_failed',
  disabled: 'status_canceled',
  unknown: 'status_warning',
  offline: 'status_canceled',
};

export const HEALTH_STATUS_CLASS = {
  healthy: 'text-success-500',
  unhealthy: 'text-danger-500',
  disabled: 'text-secondary-950',
  unknown: 'cdark',
  offline: 'cdark',
};

export const TIME_DIFF = {
  FIVE_MINS: 300,
  HOUR: 3600,
};

export const STATUS_DELAY_THRESHOLD_MS = 60000;

export const HELP_INFO_URL =
  'https://docs.gitlab.com/ee/administration/geo/disaster_recovery/background_verification.html#repository-verification';
