<script>

import {
  GlForm,
  GlToggle,
  GlFormGroup,
  GlTooltip,
  GlTooltipDirective,
  GlButton,
  GlLink,
  GlFormInput,
  GlSprintf,
 
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
    GlFormInput,
    GlSprintf,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
  },

  computed: {
    ...mapState(['enabled', 'editable', 'multiple']),
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
  <div>
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

    <gl-form-group v-if="multiple"
      id="environment_scope"
      class="col-md-6"
      :label="s__('ClusterIntegration|Environment scope')"
      label-size="sm"
      :description="s__('ClusterIntegration|Choose which of your environments will use this cluster.')"
      label-for="environment_scope"
      >
      <gl-form-input id="environment_scope" />
    </gl-form-group>

    <gl-form-group v-else
      id="environment_scope"
      class="col-md-6"
      :label="s__('ClusterIntegration|Environment scope')"
      label-size="sm"
      :description="s__('ClusterIntegration| <code>*</code> is the default environment scope for this cluster. This means that all jobs, regardless of their environment, will use this cluster.')"
      label-for="environment_scope"
      value="*"
      disabled="disabled"
      >
      <gl-form-input id="environment_scope" />
    </gl-form-group>
  </div>
</template>
