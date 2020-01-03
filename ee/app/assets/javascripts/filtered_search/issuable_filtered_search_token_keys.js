import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import {
  tokenKeys,
  alternativeTokenKeys,
  conditions,
} from '~/filtered_search/issuable_filtered_search_token_keys';
import { __ } from '~/locale';

const weightTokenKey = {
  formattedKey: __('Weight'),
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
    operator: '=',
    tokenKey: 'weight',
    value: __('None'),
  },
  {
    url: 'weight=Any',
    operator: '=',
    tokenKey: 'weight',
    value: __('Any'),
  },
  {
    url: 'not[weight]=None',
    operator: '!=',
    tokenKey: 'weight',
    value: __('None'),
  },
  {
    url: 'not[weight]=Any',
    operator: '!=',
    tokenKey: 'weight',
    value: __('Any'),
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

    // Add the original as an alternative token key
    this.tokenKeysWithAlternative.push({ ...assigneeTokenKey });

    assigneeTokenKey.type = 'array';
    assigneeTokenKey.param = 'username[]';
  }
}

export default new IssuesFilteredSearchTokenKeysEE();
