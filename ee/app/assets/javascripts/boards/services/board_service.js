import BoardService from '~/boards/services/board_service';
import boardsStore from '~/boards/stores/boards_store';

export default class BoardServiceEE extends BoardService {
  static updateWeight(endpoint, weight = null) {
    return boardsStore.updateWeight(endpoint, weight);
  }
}
