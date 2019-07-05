import $ from 'jquery';
import initNewListDropdown from '~/boards/components/new_list_dropdown';
import AssigneeList from './assignees_list_slector';
import MilestoneList from './milestone_list_selector';

const handleDropdownHide = e => {
  const $currTarget = $(e.currentTarget);
  if ($currTarget.data('preventClose')) {
    e.preventDefault();
  }
  $currTarget.removeData('preventClose');
};

let assigneeList;
let milstoneList;

const handleDropdownTabClick = e => {
  const $addListEl = $('#js-add-list');
  $addListEl.data('preventClose', true);
  if (e.target.dataset.action === 'tab-assignees' && !assigneeList) {
    assigneeList = AssigneeList();
  }

  if (e.target.dataset.action === 'tab-milestones' && !milstoneList) {
    milstoneList = MilestoneList();
  }
};

export default () => {
  initNewListDropdown();

  $('#js-add-list').on('hide.bs.dropdown', handleDropdownHide);
  $('.js-new-board-list-tabs').on('click', handleDropdownTabClick);
};
