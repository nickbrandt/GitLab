<script>
import { GlLoadingIcon } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import VulnerabilityStateDropdown from './vulnerability_state_dropdown.vue';

export default {
  components: { GlLoadingIcon, VulnerabilityStateDropdown },

  props: {
    state: { type: String, required: true },
    id: { type: Number, required: true },
  },

  data: () => ({
    isLoading: false,
  }),

  methods: {
    onVulnerabilityStateChange(newState) {
      this.isLoading = true;

      axios
        .post(`/api/v4/vulnerabilities/${this.id}/${newState}`)
        // Reload the page for now since the rest of the page is still a static haml file.
        .then(() => window.location.reload(true))
        .catch(() => {
          createFlash(
            s__(
              'VulnerabilityManagement|Something went wrong, could not update vulnerability state.',
            ),
          );
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <div class="vulnerability-show-header">
    <gl-loading-icon v-if="isLoading" />
    <vulnerability-state-dropdown v-else :state="state" @change="onVulnerabilityStateChange" />
  </div>
</template>
