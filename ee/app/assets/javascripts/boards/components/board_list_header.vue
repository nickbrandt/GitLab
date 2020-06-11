<script>
import { mapState, mapActions } from 'vuex';
import BoardListHeaderFoss from '~/boards/components/board_list_header.vue';
import { __, sprintf, s__ } from '~/locale';
import boardsStore from '~/boards/stores/boards_store';
import { inactiveListId } from '~/boards/constants';
import eventHub from '~/sidebar/event_hub';

export default {
  extends: BoardListHeaderFoss,
  data() {
    return {
      weightFeatureAvailable: boardsStore.weightFeatureAvailable,
    };
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
      return BoardListHeaderFoss.computed.issuesTooltip.call(this);
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
      if (this.activeListId === inactiveListId) {
        eventHub.$emit('sidebar.closeAll');
      }

      this.setActiveListId(this.list.id);
    },
  },
};
</script>
