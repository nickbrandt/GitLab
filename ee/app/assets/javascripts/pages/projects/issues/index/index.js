import '~/pages/projects/issues/index/index';
import Stats from 'ee/stats';

document.addEventListener('DOMContentLoaded', () => {
  Stats.bindTrackableContainer('.issues-export-modal');
  Stats.bindTrackableContainer('.issues-import-modal');
});
