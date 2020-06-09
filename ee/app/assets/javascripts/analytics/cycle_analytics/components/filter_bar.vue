<script>
import { mapState } from 'vuex';
import { GlFilteredSearch } from '@gitlab/ui';

export default {
  name: 'FilterBar',
  components: {
    GlFilteredSearch,
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchTerms: [],
    };
  },
  computed: {
    ...mapState('filters', ['milestonesPath', 'labelsPath']),
  },
};
</script>
<template>
  <gl-filtered-search
    :disabled="disabled"
    :v-model="searchTerms"
    :placeholder="__('Filter results')"
    :clear-button-title="__('Clear')"
    :close-button-title="__('Close')"
  />
</template>
