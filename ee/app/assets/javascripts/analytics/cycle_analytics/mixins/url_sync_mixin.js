import { mapState, mapGetters } from 'vuex';
import { historyPushState } from '~/lib/utils/common_utils';
import { setUrlParams } from '~/lib/utils/url_utility';
import { toYmd } from '../../shared/utils';

export default {
  computed: {
    ...mapGetters(['currentGroupPath', 'selectedProjectIds']),
    ...mapState(['startDate', 'endDate']),
    query() {
      return {
        group_id: this.currentGroupPath,
        'project_ids[]': this.selectedProjectIds,
        created_after: toYmd(this.startDate),
        created_before: toYmd(this.endDate),
      };
    },
  },
  watch: {
    query() {
      historyPushState(setUrlParams(this.query, window.location.href, true));
    },
  },
};
