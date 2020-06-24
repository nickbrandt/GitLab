<script>
/*
 * This component shows a subepic icon indicator if a list of issues are
 * filtered by epic id.
 */
import { GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip,
  },
  props: {
    issueEpic: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    filterEpicId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    issueInSubepic() {
      const { filterEpicId, issueEpic } = this;
      const issueEpicId = issueEpic?.id;

      if (!filterEpicId || !issueEpicId) {
        return false;
      }

      // An issue is member of a subepic when its epic id is different
      // than the filter epic id on the URL search parameters.
      return filterEpicId !== issueEpicId;
    },
  },
};
</script>

<template>
  <span
    v-if="issueInSubepic"
    v-gl-tooltip
    :title="__('This issue is in a child epic of the filtered epic')"
    class="gl-display-inline-block gl-ml-1"
  >
    <gl-icon
      name="information-o"
      class="gl-display-block gl-text-blue-500 hover-text-primary-800"
    />
  </span>
</template>
