<script>
import { mapState } from 'vuex';
import { GlFormGroup, GlFormInput, GlButton } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  name: 'GeoSettingsForm',
  components: {
    GlFormGroup,
    GlFormInput,
    GlButton,
  },
  computed: {
    // The real connection between vuex and the component will be implemented in
    // a later MR, this feature is anyhow behind feature flag
    ...mapState(['timeout', 'allowedIp']),
  },
  methods: {
    redirect() {
      visitUrl('/admin/geo/nodes');
    },
  },
};
</script>

<template>
  <form>
    <gl-form-group
      :label="__('Connection timeout')"
      label-for="settings-timeout-field"
      :description="__('Time in seconds')"
    >
      <gl-form-input id="settings-timeout-field" v-model="timeout" class="col-sm-2" type="number" />
    </gl-form-group>
    <gl-form-group
      :label="__('Allowed Geo IP')"
      label-for="settings-allowed-ip-field"
      :description="__('Comma-separated, e.g. \'1.1.1.1, 2.2.2.0/24\'')"
    >
      <gl-form-input
        id="settings-allowed-ip-field"
        v-model="allowedIp"
        class="col-sm-6"
        type="text"
      />
    </gl-form-group>
    <section
      class="gl-display-flex gl-align-items-center gl-p-5 gl-mt-6 gl-bg-gray-10 gl-border-t-solid gl-border-b-solid gl-border-t-1 gl-border-b-1 gl-border-gray-200"
    >
      <gl-button
        data-testid="settingsSaveButton"
        data-qa-selector="add_node_button"
        variant="success"
        >{{ __('Save changes') }}</gl-button
      >
      <gl-button data-testid="settingsCancelButton" class="gl-ml-auto" @click="redirect">{{
        __('Cancel')
      }}</gl-button>
    </section>
  </form>
</template>
