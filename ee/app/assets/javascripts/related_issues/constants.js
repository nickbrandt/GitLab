import { __ } from '~/locale';

export const autoCompleteTextMap = {
  true: {
    issue: __(' or <#issue id>'),
    epic: __(' or <#epic id>'),
  },
  false: {
    issue: '',
    epic: '',
  },
};

export const inputPlaceholderTextMap = {
  issue: __('Paste issue link'),
  epic: __('Paste epic link'),
};

export const relatedIssuesRemoveErrorMap = {
  issue: __('An error occurred while removing issues.'),
  epic: __('An error occurred while removing epics.'),
};

export const pathIndeterminateErrorMap = {
  issue: __('We could not determine the path to remove the issue'),
  epic: __('We could not determine the path to remove the epic'),
};

export const addRelatedIssueErrorMap = {
  issue: __("We can't find an issue that matches what you are looking for."),
  epic: __("We can't find an epic that matches what you are looking for."),
};

/**
 * These are used to map issuableType to the correct icon.
 * Since these are never used for any display purposes, don't wrap
 * them inside i18n functions.
 */
export const issuableIconMap = {
  issue: 'issues',
  epic: 'epic',
};

/**
 * These are used to map issuableType to the correct QA class.
 * Since these are never used for any display purposes, don't wrap
 * them inside i18n functions.
 */
export const issuableQaClassMap = {
  issue: 'qa-add-issues-button',
  epic: 'qa-add-epics-button',
};
