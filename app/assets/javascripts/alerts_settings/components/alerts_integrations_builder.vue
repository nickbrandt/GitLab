<script>
import { __ } from '~/locale';
import { GlTabs, GlTab, GlPath } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { i18n } from '../constants';

export default {
  i18n,
  items: [
    {
      title: __('Select Type (Custom)'),
      step: 'select',
    },
    {
      title: __('Configure'),
      step: 'configure',
      selected: true,
    },
    {
      title: __('Finalize'),
      step: 'finalize',
    },
  ],
  components: {
    GlTabs,
    GlTab,
    GlPath,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {},

  data() {
    return {
      activeStep: this.$options.items[1].step,
    };
  },
  computed: {},

  methods: {
    setActiveStep(path) {
      this.activeStep = path.step;
    },
  },
};
</script>

<template>
  <div>
    <gl-tabs>
      <gl-tab :title="__('Integrations')">
        <gl-path :items="$options.items" theme="light-blue" @selected="setActiveStep" />

        <div v-if="activeStep === 'configure'">
          Configure stage
        </div>
        <div v-if="activeStep === 'finalize'">
          Finalize stage
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
