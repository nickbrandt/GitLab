import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import {
  tokenKeys,
  alternativeTokenKeys,
  conditions,
} from '~/filtered_search/issuable_filtered_search_token_keys';

const weightTokenKey = {
  key: 'weight',
  type: 'string',
  param: '',
  symbol: '',
  icon: 'weight',
  tag: 'number',
};

const weightConditions = [
  {
    url: 'weight=None',
    tokenKey: 'weight',
    value: 'None',
  },
  {
    url: 'weight=Any',
    tokenKey: 'weight',
    value: 'Any',
  },
];

/**
 * Filter tokens for issues in EE.
 */
class IssuesFilteredSearchTokenKeysEE extends FilteredSearchTokenKeys {
  constructor() {
    super([...tokenKeys, weightTokenKey], alternativeTokenKeys, [
      ...conditions,
      ...weightConditions,
    ]);
  }

  /**
   * Changes assignee token to accept multiple values.
   */
  enableMultipleAssignees() {
    const assigneeTokenKey = this.tokenKeys.find(tk => tk.key === 'assignee');
    assigneeTokenKey.type = 'array';
    assigneeTokenKey.param = 'username[]';
  }
}

export default new IssuesFilteredSearchTokenKeysEE();
