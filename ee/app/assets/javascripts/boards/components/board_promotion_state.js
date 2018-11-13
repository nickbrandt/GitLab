import boardsStore from '~/boards/stores/boards_store';

export default {
  template: '#js-board-promotion',
  methods: {
    clearPromotionState: boardsStore.removePromotionState.bind(boardsStore),
  },
};
