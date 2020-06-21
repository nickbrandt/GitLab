<script>

import {
  GlForm,
  GlToggle,
  GlFormGroup,
  GlTooltip,
  GlTooltipDirective,
  GlButton,
  GlLink,
} from '@gitlab/ui';

import { s__, __, sprintf } from '~/locale';

import { mapState, mapActions } from 'vuex';

export default {
  components: {
    GlFormGroup,
    GlForm,
    GlToggle,
    GlTooltip,
    GlLink,
    GlButton,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
  },

  computed: {
    ...mapState(['enabled', 'editable']),
  },


  mounted() {
    this.toggleEnabled = this.enabled;
  },

  data() {
    return {
      toggleEnabled: true,
    };
  },
};
</script>

<template>
  <div class="d-flex align-items-center">
    
      <gl-form-group>
        <div class="gl-display-flex gl-align-items-center">
          <h4 class="gl-pr-3 gl-m-0 ">{{ s__('ClusterIntegration|GitLab Integration') }}</h4>
          <input
            class="js-project-feature-toggle-input"
            type="hidden"
            :value="toggleEnabled"

            name="cluster[enabled]"
            id="cluster_enabled"
          />
          <div id="tooltipcontainer">
            <gl-toggle
              class="gl-mb-0"
              :disabled="!editable"
              :is_checked="toggleEnabled"
              :aria-describedby="__('Toggle Kubernetes cluster')"
              v-model="toggleEnabled"
              v-gl-tooltip:tooltipcontainer
              :title="
                s__(
                  'ClusterIntegration|Enable or disable GitLab\'s connection to your Kubernetes cluster.',
                )
              "
            />
          </div>
        </div>
      </gl-form-group>
  
  </div>
</template>
