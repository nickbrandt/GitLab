<script>
import Tracking from '~/tracking';
import { trackInstallationTabChange } from '../utils';
import { GlTab, GlTabs } from '@gitlab/ui';

export default {
  name: 'TabWrapper',
  components: {
    GlTab,
    GlTabs,
  },
  mixins: [Tracking.mixin(), trackInstallationTabChange],
  props: {
    trackingLabel: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="append-bottom-default">
    <gl-tabs @input="trackInstallationTabChange">
      <gl-tab :title="s__('PackageRegistry|Installation')" title-item-class="js-installation-tab">
        <div class="prepend-left-default append-right-default">
          <slot name="installation"></slot>
        </div>
      </gl-tab>
      <gl-tab :title="s__('PackageRegistry|Registry Setup')" title-item-class="js-setup-tab">
        <div class="prepend-left-default append-right-default">
          <slot name="setup"></slot>
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
