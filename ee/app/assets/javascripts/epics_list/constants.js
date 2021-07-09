import { AvailableSortOptions } from '~/issuable_list/constants';
import { __ } from '~/locale';

export const EpicsSortOptions = [
  {
    id: AvailableSortOptions.length + 10,
    title: __('Start date'),
    sortDirection: {
      descending: 'start_date_desc',
      ascending: 'start_date_asc',
    },
  },
  {
    id: AvailableSortOptions.length + 20,
    title: __('Due date'),
    sortDirection: {
      descending: 'end_date_desc',
      ascending: 'end_date_asc',
    },
  },
  {
    id: AvailableSortOptions.length + 30,
    title: __('Title'),
    sortDirection: {
      descending: 'title_desc',
      ascending: 'title_asc',
    },
  },
];

export const FilterStateEmptyMessage = {
  opened: __('There are no open epics'),
  closed: __('There are no closed epics'),
};
