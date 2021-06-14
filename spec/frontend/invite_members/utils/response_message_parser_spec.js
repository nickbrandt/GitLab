import {
  responseMessageFromSuccess,
  responseMessageFromError,
} from '~/invite_members/utils/response_message_parser';

describe('Response message parser', () => {
  describe('parse message from successful response', () => {
    const expectedMessage = 'expected display message';
    const exampleKeyedMsg = { 'email@example.com': expectedMessage };
    const exampleUserMsgMultiple =
      ' and username1: id not found and username2: email is restricted';

    const successResponses = [
      [{ data: { message: expectedMessage } }],
      [{ data: { message: expectedMessage + exampleUserMsgMultiple } }],
      [{ data: { error: expectedMessage } }],
      [{ data: { message: [expectedMessage] } }],
      [{ data: { message: exampleKeyedMsg } }],
    ];

    successResponses.forEach((successResponse) => {
      it(`returns ${expectedMessage} from successResponse: ${JSON.stringify(
        successResponse,
      )}`, () => {
        expect(responseMessageFromSuccess(successResponse)).toBe(expectedMessage);
      });
    });
  });

  describe('message from error response', () => {
    const expectedMessage = 'expected display message';

    const errorResponses = [
      { response: { data: { error: expectedMessage } } },
      { response: { data: { message: { user: [expectedMessage] } } } },
      { response: { data: { message: { access_level: [expectedMessage] } } } },
      { response: { data: { message: { error: expectedMessage } } } },
      { response: { data: { message: expectedMessage } } },
    ];

    errorResponses.forEach((errorResponse) => {
      it(`returns ${expectedMessage} from errorResponse: ${JSON.stringify(errorResponse)}`, () => {
        expect(responseMessageFromError(errorResponse)).toBe(expectedMessage);
      });
    });
  });
});
