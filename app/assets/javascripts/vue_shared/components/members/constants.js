import { __ } from '~/locale';

export const FIELDS = [
  {
    key: 'account',
    label: __('Account'),
  },
  {
    key: 'source',
    label: __('Source'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: 'granted',
    label: __('Access Granted'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: 'invited',
    label: __('Invited'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: 'requested',
    label: __('Requested'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: 'expires',
    label: __('Access Expires'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: 'maxRole',
    label: __('Max Role'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: 'expiration',
    label: __('Expiration'),
    thClass: 'col-expiration',
    tdClass: 'col-expiration',
  },
  {
    key: 'actions',
    thClass: 'col-actions',
    tdClass: 'col-actions',
  },
];
