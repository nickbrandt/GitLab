import { mapActions, mapState } from 'vuex';
import boardPromotionState from 'ee/boards/components/board_promotion_state';
import { GlTooltip } from '@gitlab/ui';
import Board from '~/boards/components/board';
import { __, sprintf, s__ } from '~/locale';
import boardsStore from '~/boards/stores/boards_store';
import eventHub from '~/sidebar/event_hub';

/**
 * Please have a look at:
 * ./board_column.vue
 * https://gitlab.com/gitlab-org/gitlab/-/issues/212300
 * @deprecated
 */
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
    ...mapState(['activeListId']),
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
      // If no list is opened, close all sidebars first
      if (!this.activeListId) {
        eventHub.$emit('sidebar.closeAll');
      }
      this.setActiveListId(this.list.id);
    },
  },
});
