/* eslint-disable class-methods-use-this */

import BoardService from '~/boards/services/board_service';
import boardsStore from '~/boards/stores/boards_store';

export default class BoardServiceEE extends BoardService {
  allBoards() {
    return boardsStore.allBoards();
  }

  recentBoards() {
    return boardsStore.recentBoards();
  }

  createBoard(board) {
    return boardsStore.createBoard(board);
  }

  deleteBoard({ id }) {
    return boardsStore.deleteBoard({ id });
  }

  static updateWeight(endpoint, weight = null) {
    return boardsStore.updateWeight(endpoint, weight);
  }
}
