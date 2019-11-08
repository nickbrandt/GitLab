import { __ } from '~/locale';

// These statuses are based on how the backend defines pod phases here
// lib/gitlab/kubernetes/pod.rb

const STATUS_MAP = {
  succeeded: {
    class: 'succeeded',
    text: __('Succeeded'),
    stable: true,
  },
  running: {
    class: 'running',
    text: __('Running'),
    stable: true,
  },
  failed: {
    class: 'failed',
    text: __('Failed'),
    stable: true,
  },
  pending: {
    class: 'pending',
    text: __('Pending'),
    stable: true,
  },
  unknown: {
    class: 'unknown',
    text: __('Unknown'),
    stable: true,
  },
};

export default STATUS_MAP;
