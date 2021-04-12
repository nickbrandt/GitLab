<script>
import { GlSegmentedControl } from '@gitlab/ui';
import { __ } from '~/locale';
import { STAGE_VIEW, LAYER_VIEW } from './constants';

export default {
  name: 'GraphViewSelector',
  components: {
    GlSegmentedControl,
  },
  props: {
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      currentViewType: STAGE_VIEW,
    };
  },
  i18n: {
    labelText: __('Group jobs by'),
  },
  views: {
    [STAGE_VIEW]: {
      type: STAGE_VIEW,
      text: {
        primary: __('Stage'),
        secondary: __('Group jobs into stages'),
      },
    },
    [LAYER_VIEW]: {
      type: LAYER_VIEW,
      text: {
        primary: __('Job dependencies'),
        secondary: __('Group jobs by configured dependencies'),
      },
    },
  },
  computed: {
    viewTypesList() {
      return Object.keys(this.$options.views).map((key) => {
        return {
          value: key,
          text: this.$options.views[key].text.primary,
        };
      });
    },
  },
  methods: {
    itemClick(type) {
      this.$emit('updateViewType', type);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-my-4">
    <span class="gl-font-weight-bold">{{ $options.i18n.labelText }}</span>
    <gl-segmented-control
      :checked="currentViewType"
      :options="viewTypesList"
      data-testid="pipeline-view-selector"
      class="gl-ml-4"
      @input="itemClick"
    />
  </div>
</template>
