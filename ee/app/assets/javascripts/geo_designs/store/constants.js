export const FILTER_STATES = {
  ALL: 'all',
  SYNCED: 'synced',
  PENDING: 'pending',
  FAILED: 'failed',
};

export const DEFAULT_STATUS = 'never';

export const STATUS_ICON_NAMES = {
  [FILTER_STATES.SYNCED]: 'status_closed',
  [FILTER_STATES.PENDING]: 'status_scheduled',
  [FILTER_STATES.FAILED]: 'status_failed',
  [DEFAULT_STATUS]: 'status_notfound',
};

export const STATUS_ICON_CLASS = {
  [FILTER_STATES.SYNCED]: 'text-success',
  [FILTER_STATES.PENDING]: 'text-warning',
  [FILTER_STATES.FAILED]: 'text-danger',
  [DEFAULT_STATUS]: 'text-muted',
};
