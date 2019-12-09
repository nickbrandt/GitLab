import boardPromotionState from 'ee/boards/components/board_promotion_state';
import Board from '~/boards/components/board';
import { __, n__, sprintf } from '~/locale';
import boardsStore from '~/boards/stores/boards_store';

export default Board.extend({
  data() {
    return {
      weightFeatureAvailable: boardsStore.weightFeatureAvailable,
    };
  },
  components: {
    boardPromotionState,
  },
  computed: {
    counterTooltip() {
      if (!this.weightFeatureAvailable) {
        // call computed property from base component (CE board.js)
        return Board.options.computed.counterTooltip.call(this);
      }

      const { issuesSize, totalWeight } = this.list;
      return sprintf(
        __(`${n__('%d issue', '%d issues', issuesSize)} with %{totalWeight} total weight`),
        {
          totalWeight,
        },
      );
    },
  },
});
