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

  let service;
  let axiosMock;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);

    boardsStore.setEndpoints({
      ...endpoints,
      boardId,
    });

    service = new BoardServiceEE();
  });

  describe('allBoards', () => {
    const url = `${endpoints.boardsEndpoint}.json`;

    it('makes a request to fetch all boards', () => {
      axiosMock.onGet(url).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(service.allBoards()).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(url).replyOnce(500);

      return expect(service.allBoards()).rejects.toThrow();
    });
  });

  describe('recentBoards', () => {
    const url = `${endpoints.recentBoardsEndpoint}.json`;

    it('makes a request to fetch all boards', () => {
      axiosMock.onGet(url).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(service.recentBoards()).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(url).replyOnce(500);

      return expect(service.recentBoards()).rejects.toThrow();
    });
  });

  describe('createBoard', () => {
    const labelIds = ['first label', 'second label'];
    const assigneeId = 'as sign ee';
    const milestoneId = 'vegetable soup';
    const board = {
      labels: labelIds.map(id => ({ id })),
      assignee: { id: assigneeId },
      milestone: { id: milestoneId },
    };

    describe('for existing board', () => {
      const id = 'skate-board';
      const url = `${endpoints.boardsEndpoint}/${id}.json`;
      const expectedRequest = expect.objectContaining({
        data: JSON.stringify({
          board: {
            ...board,
            id,
            label_ids: labelIds,
            assignee_id: assigneeId,
            milestone_id: milestoneId,
          },
        }),
      });

      let requestSpy;

      beforeEach(() => {
        requestSpy = jest.fn();
        axiosMock.onPut(url).replyOnce(config => requestSpy(config));
      });

      it('makes a request to update the board', () => {
        requestSpy.mockReturnValue([200, dummyResponse]);
        const expectedResponse = expect.objectContaining({ data: dummyResponse });

        return expect(
          service.createBoard({
            ...board,
            id,
          }),
        )
          .resolves.toEqual(expectedResponse)
          .then(() => {
            expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
          });
      });

      it('fails for error response', () => {
        requestSpy.mockReturnValue([500]);

        return expect(
          service.createBoard({
            ...board,
            id,
          }),
        )
          .rejects.toThrow()
          .then(() => {
            expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
          });
      });
    });

    describe('for new board', () => {
      const url = `${endpoints.boardsEndpoint}.json`;
      const expectedRequest = expect.objectContaining({
        data: JSON.stringify({
          board: {
            ...board,
            label_ids: labelIds,
            assignee_id: assigneeId,
            milestone_id: milestoneId,
          },
        }),
      });

      let requestSpy;

      beforeEach(() => {
        requestSpy = jest.fn();
        axiosMock.onPost(url).replyOnce(config => requestSpy(config));
      });

      it('makes a request to create a new board', () => {
        requestSpy.mockReturnValue([200, dummyResponse]);
        const expectedResponse = expect.objectContaining({ data: dummyResponse });

        return expect(service.createBoard(board))
          .resolves.toEqual(expectedResponse)
          .then(() => {
            expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
          });
      });

      it('fails for error response', () => {
        requestSpy.mockReturnValue([500]);

        return expect(service.createBoard(board))
          .rejects.toThrow()
          .then(() => {
            expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
          });
      });
    });
  });

  describe('deleteBoard', () => {
    const id = 'capsized';
    const url = `${endpoints.boardsEndpoint}/${id}.json`;

    it('makes a request to delete a boards', () => {
      axiosMock.onDelete(url).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(service.deleteBoard({ id })).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onDelete(url).replyOnce(500);

      return expect(service.deleteBoard({ id })).rejects.toThrow();
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
