import addExtraTokensForMergeRequests from '~/filtered_search/add_extra_tokens_for_merge_requests';
import { __ } from '~/locale';

export default IssuableTokenKeys => {
  addExtraTokensForMergeRequests(IssuableTokenKeys);

  const approversConditions = [
    {
      url: 'approver_usernames[]=None',
      tokenKey: 'approver',
      value: __('None'),
    },
    {
      url: 'approver_usernames[]=Any',
      tokenKey: 'approver',
      value: __('Any'),
    },
  ];

  const approversToken = {
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
