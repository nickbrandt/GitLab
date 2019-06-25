import $ from 'jquery';
import IssuableBulkUpdateSidebar from './issuable_bulk_update_sidebar';
import issuableBulkUpdateActions from './issuable_bulk_update_actions';

export default {
  bulkUpdateSidebar: null,

  init(prefixId) {
    const userCanBulkUpdate = $('.issues-bulk-update').length > 0;
    const alreadyInitialized = Boolean(this.bulkUpdateSidebar);

    if (userCanBulkUpdate && !alreadyInitialized) {
      issuableBulkUpdateActions.init({ prefixId });

      this.bulkUpdateSidebar = new IssuableBulkUpdateSidebar();
    }

    return this.bulkUpdateSidebar;
  },
};
