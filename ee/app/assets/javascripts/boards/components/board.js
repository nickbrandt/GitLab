import { mapActions } from 'vuex';
import boardPromotionState from 'ee/boards/components/board_promotion_state';
import { GlTooltip } from '@gitlab/ui';
import Board from '~/boards/components/board';
import { __, sprintf, s__ } from '~/locale';
import boardsStore from '~/boards/stores/boards_store';

export default Board.extend({
  data() {
    return {
      weightFeatureAvailable: boardsStore.weightFeatureAvailable,
    };
  },
  components: {
    GlTooltip,
    boardPromotionState,
  },
  computed: {
    issuesTooltip() {
      const { issuesSize, maxIssueCount } = this.list;

      if (maxIssueCount > 0) {
        return sprintf(__('%{issuesSize} issues with a limit of %{maxIssueCount}'), {
          issuesSize,
          maxIssueCount,
        });
      }

      // TODO: Remove this pattern.
      return Board.options.computed.issuesTooltip.call(this);
    },
    weightCountToolTip() {
      const { totalWeight } = this.list;

      if (this.weightFeatureAvailable) {
        return sprintf(s__('%{totalWeight} total weight'), { totalWeight });
      }

      return null;
    },
  },
  methods: {
    ...mapActions(['setActiveListId']),
    openSidebarSettings() {
      this.setActiveListId(this.list.id);
    },
  },
});
