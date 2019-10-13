/**
 * This file is intended to be deleted.
 * The existing functions will removed one by one in favor of using the board store directly.
 * see https://gitlab.com/gitlab-org/gitlab-foss/issues/61621
 */

import BoardService from '~/boards/services/board_service';
import boardsStore from '~/boards/stores/boards_store';

export default class BoardServiceEE extends BoardService {
  static updateWeight(endpoint, weight = null) {
    return boardsStore.updateWeight(endpoint, weight);
  }
}
