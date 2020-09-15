import {
  createUnexpectedCommitError,
  createCodeownersCommitError,
  createBranchChangedCommitError,
  parseCommitError,
} from '~/ide/lib/errors';

const TEST_MESSAGE = 'Test message';
const TEST_MESSAGE_WITH_SENTENCE = 'Test message.';
const TEST_MESSAGE_WITH_SENTENCE_AND_SPACE = 'Test message. ';
const CODEOWNERS_MESSAGE =
  'Push to protected branches that contain changes to files matching CODEOWNERS is not allowed';
const CHANGED_MESSAGE = 'Things changed since you started editing';

describe('~/ide/lib/errors', () => {
  const createResponseError = message => ({
    response: {
      data: {
        message,
      },
    },
  });

  describe('createCodeownersCommitError', () => {
    it('uses given message', () => {
      expect(createCodeownersCommitError(TEST_MESSAGE)).toEqual({
        title: 'CODEOWNERS rule violation',
        message: TEST_MESSAGE,
        canCreateBranch: true,
      });
    });
  });

  describe('createBranchChangedCommitError', () => {
    it.each`
      message                                 | expectedMessage
      ${TEST_MESSAGE}                         | ${`${TEST_MESSAGE}. Would you like to create a new branch?`}
      ${TEST_MESSAGE_WITH_SENTENCE}           | ${`${TEST_MESSAGE}. Would you like to create a new branch?`}
      ${TEST_MESSAGE_WITH_SENTENCE_AND_SPACE} | ${`${TEST_MESSAGE}. Would you like to create a new branch?`}
    `('uses given message="$message"', ({ message, expectedMessage }) => {
      expect(createBranchChangedCommitError(message)).toEqual({
        title: 'Branch changed',
        message: expectedMessage,
        canCreateBranch: true,
      });
    });
  });

  describe('parseCommitError', () => {
    it.each`
      message                                    | expectation
      ${null}                                    | ${createUnexpectedCommitError()}
      ${{}}                                      | ${createUnexpectedCommitError()}
      ${{ response: {} }}                        | ${createUnexpectedCommitError()}
      ${{ response: { data: {} } }}              | ${createUnexpectedCommitError()}
      ${createResponseError('test')}             | ${createUnexpectedCommitError()}
      ${createResponseError(CODEOWNERS_MESSAGE)} | ${createCodeownersCommitError(CODEOWNERS_MESSAGE)}
      ${createResponseError(CHANGED_MESSAGE)}    | ${createBranchChangedCommitError(CHANGED_MESSAGE)}
    `('parses message into error object with "$message"', ({ message, expectation }) => {
      expect(parseCommitError(message)).toEqual(expectation);
    });
  });
});
