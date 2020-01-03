import addExtraTokensForMergeRequests from '~/filtered_search/add_extra_tokens_for_merge_requests';
import { __ } from '~/locale';

export default IssuableTokenKeys => {
  addExtraTokensForMergeRequests(IssuableTokenKeys);

  const approversConditions = [
    {
      url: 'approver_usernames[]=None',
      tokenKey: 'approver',
      value: __('None'),
      operator: '=',
    },
    {
      url: 'not[approver_usernames][]=None',
      tokenKey: 'approver',
      value: __('None'),
      operator: '!=',
    },
    {
      url: 'approver_usernames[]=Any',
      tokenKey: 'approver',
      value: __('Any'),
      operator: '=',
    },
    {
      url: 'not[approver_usernames][]=Any',
      tokenKey: 'approver',
      value: __('Any'),
      operator: '!=',
    },
  ];

  const approversToken = {
    formattedKey: __('Approver'),
    key: 'approver',
    type: 'array',
    param: 'usernames[]',
    symbol: '@',
    icon: 'approval',
    tag: '@approver',
  };
  const approversTokenPosition = 2;

  IssuableTokenKeys.tokenKeys.splice(approversTokenPosition, 0, approversToken);
  IssuableTokenKeys.tokenKeysWithAlternative.splice(approversTokenPosition, 0, approversToken);
  IssuableTokenKeys.conditions.push(...approversConditions);
};
