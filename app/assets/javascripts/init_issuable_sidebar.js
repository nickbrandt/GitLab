/* eslint-disable no-new */

import MilestoneSelect from './milestone_select';
import LabelsSelect from './labels_select';
import IssuableContext from './issuable_context';
import Sidebar from './right_sidebar';

import DueDateSelectors from './due_date_select';

import createDefaultClient from '~/lib/graphql';
import issueSidebarSubscription from '~/issuable_sidebar/queries/issueSidebar.subscription.graphql';

export default () => {
  const sidebarOptions = JSON.parse(document.querySelector('.js-sidebar-options').innerHTML);

  new MilestoneSelect({
    full_path: sidebarOptions.fullPath,
  });
  new LabelsSelect();
  new IssuableContext(sidebarOptions.currentUser);
  new DueDateSelectors();
  Sidebar.initialize();

  if (sidebarOptions.type === 'issue') {
    createDefaultClient()
      .subscribe({
        query: issueSidebarSubscription,
        variables: {
          id: sidebarOptions.id,
        },
      })
      .subscribe({
        next(data) {
          console.log(data);
        },
        error(data) {
          console.log(data);
        },
      });
  }
};
