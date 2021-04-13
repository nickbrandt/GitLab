<script>
import { GlSegmentedControl, GlToggle } from '@gitlab/ui';
import { __ } from '~/locale';
import { STAGE_VIEW, LAYER_VIEW } from './constants';

export default {
  name: 'GraphViewSelector',
  components: {
    GlSegmentedControl,
    GlToggle,
  },
  props: {
    linksLoading: {
      type: Boolean,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      currentViewType: this.type,
      showLinks: false,
    };
  },
  i18n: {
    viewLabelText: __('Group jobs by'),
    linksLabelText: __('Show dependencies'),
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
  watch: {
    showLinks(val) {
      this.$emit('updateShowLinks', val);
    },
  },
  computed: {
    showLinksToggle() {
      return this.currentViewType === LAYER_VIEW;
    },
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
    updateShowLinks(val) {
      this.showLinks = val;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-my-4">
    <span class="gl-font-weight-bold">{{ $options.i18n.viewLabelText }}</span>
    <gl-segmented-control
      v-model="currentViewType"
      :options="viewTypesList"
      data-testid="pipeline-view-selector"
      class="gl-mx-4"
      @input="itemClick"
    />
    <div v-if="showLinksToggle">
      <gl-toggle
        v-model="showLinks"
        class="gl-mx-4"
        :label="$options.i18n.linksLabelText"
        :is-loading="linksLoading"
        label-position="left"
        @change="updateShowLinks"
      />
    </div>
  </div>
</template>
