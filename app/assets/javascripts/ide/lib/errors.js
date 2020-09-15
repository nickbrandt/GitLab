import { __ } from '~/locale';
import { joinSentences } from '~/lib/utils/text_utility';

const CODEOWNERS_REGEX = /Push.*protected branches.*CODEOWNERS/;
const BRANCH_CHANGED_REGEX = /changed.*since.*start.*edit/;

export const createUnexpectedCommitError = () => ({
  title: __('Unexpected error'),
  message: __('Could not commit. An unexpected error occurred.'),
  canCreateBranch: false,
});

export const createCodeownersCommitError = message => ({
  title: __('CODEOWNERS rule violation'),
  message,
  canCreateBranch: true,
});

export const createBranchChangedCommitError = message => ({
  title: __('Branch changed'),
  message: joinSentences(message, __('Would you like to create a new branch?')),
  canCreateBranch: true,
});

export const parseCommitError = e => {
  const { message } = e?.response?.data || {};

  if (!message) {
    return createUnexpectedCommitError();
  }

  if (CODEOWNERS_REGEX.test(message)) {
    return createCodeownersCommitError(message);
  } else if (BRANCH_CHANGED_REGEX.test(message)) {
    return createBranchChangedCommitError(message);
  }

  return createUnexpectedCommitError();
};
