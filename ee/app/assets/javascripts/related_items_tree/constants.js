import { s__ } from '~/locale';
import { issuableTypesMap } from 'ee/related_issues/constants';

export const ChildType = {
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  Epic: 'Epic',
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  Issue: 'Issue',
};

export const ChildState = {
  Open: 'opened',
  Closed: 'closed',
};

export const PathIdSeparator = {
  Epic: '&',
  Issue: '#',
};

export const idProp = {
  Epic: 'id',
  Issue: 'epicIssueId',
};

export const relativePositions = {
  Before: 'before',
  After: 'after',
};

export const RemoveItemModalProps = {
  Epic: {
    title: s__('Epics|Remove epic'),
    body: s__(
      'Epics|This will also remove any descendents of %{bStart}%{targetEpicTitle}%{bEnd} from %{bStart}%{parentEpicTitle}%{bEnd}. Are you sure?',
    ),
  },
  Issue: {
    title: s__('Epics|Remove issue'),
    body: s__(
      'Epics|Are you sure you want to remove %{bStart}%{targetIssueTitle}%{bEnd} from %{bStart}%{parentEpicTitle}%{bEnd}?',
    ),
  },
};

export const EpicDropdownActions = [
  {
    id: 0,
    issuableType: issuableTypesMap.EPIC,
    title: s__('Epics|Add an epic'),
    description: s__('Epics|Add an existing epic as a child epic.'),
  },
  {
    id: 1,
    issuableType: issuableTypesMap.EPIC,
    title: s__('Epics|Create new epic'),
    description: s__('Epics|Create an epic within this group and add it as a child epic.'),
  },
];

export const OVERFLOW_AFTER = 5;

export const itemRemoveModalId = 'item-remove-confirmation';
