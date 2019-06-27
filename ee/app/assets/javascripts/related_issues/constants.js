import { __ } from '~/locale';

export const issuableTypesMap = {
  ISSUE: 'issue',
  EPIC: 'epic',
};

export const autoCompleteTextMap = {
  true: {
    [issuableTypesMap.ISSUE]: __(' or <#issue id>'),
    [issuableTypesMap.EPIC]: __(' or <#epic id>'),
  },
  false: {
    [issuableTypesMap.ISSUE]: '',
    [issuableTypesMap.EPIC]: '',
  },
};

export const inputPlaceholderTextMap = {
  [issuableTypesMap.ISSUE]: __('Paste issue link'),
  [issuableTypesMap.EPIC]: __('Paste epic link'),
};

export const relatedIssuesRemoveErrorMap = {
  [issuableTypesMap.ISSUE]: __('An error occurred while removing issues.'),
  [issuableTypesMap.EPIC]: __('An error occurred while removing epics.'),
};

export const pathIndeterminateErrorMap = {
  [issuableTypesMap.ISSUE]: __('We could not determine the path to remove the issue'),
  [issuableTypesMap.EPIC]: __('We could not determine the path to remove the epic'),
};

export const addRelatedIssueErrorMap = {
  [issuableTypesMap.ISSUE]: __("We can't find an issue that matches what you are looking for."),
  [issuableTypesMap.EPIC]: __("We can't find an epic that matches what you are looking for."),
};

/**
 * These are used to map issuableType to the correct icon.
 * Since these are never used for any display purposes, don't wrap
 * them inside i18n functions.
 */
export const issuableIconMap = {
  [issuableTypesMap.ISSUE]: 'issues',
  [issuableTypesMap.EPIC]: 'epic',
};

/**
 * These are used to map issuableType to the correct QA class.
 * Since these are never used for any display purposes, don't wrap
 * them inside i18n functions.
 */
export const issuableQaClassMap = {
  [issuableTypesMap.ISSUE]: 'qa-add-issues-button',
  [issuableTypesMap.EPIC]: 'qa-add-epics-button',
};
