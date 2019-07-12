import BoardServiceEE from 'ee/boards/services/board_service';

import { TEST_HOST } from 'helpers/test_constants';

import AxiosMockAdapter from 'axios-mock-adapter';

import axios from '~/lib/utils/axios_utils';
import boardsStore from '~/boards/stores/boards_store';

describe('BoardService', () => {
  const dummyResponse = 'just another response in the network';

  const boardId = 'dummy-board-id';

  const endpoints = {
    boardsEndpoint: `${TEST_HOST}/boards`,
    listsEndpoint: `${TEST_HOST}/lists`,
    bulkUpdatePath: `${TEST_HOST}/bulk/update`,
    recentBoardsEndpoint: `${TEST_HOST}/recent/boards`,
  };

  let axiosMock;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);

    boardsStore.setEndpoints({
      ...endpoints,
      boardId,
    });
  });

  describe('updateWeight', () => {
    const dummyEndpoint = `${TEST_HOST}/update/weight`;
    const weight = 'elephant';
    const expectedRequest = expect.objectContaining({ data: JSON.stringify({ weight }) });

    let requestSpy;

    beforeEach(() => {
      requestSpy = jest.fn();
      axiosMock.onPut(dummyEndpoint).replyOnce(config => requestSpy(config));
    });

    it('makes a request to update the weight', () => {
      requestSpy.mockReturnValue([200, dummyResponse]);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(BoardServiceEE.updateWeight(dummyEndpoint, weight))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(BoardServiceEE.updateWeight(dummyEndpoint, weight))
        .rejects.toThrow()
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });
  });
});
