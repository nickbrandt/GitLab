<script>
import { GlFormGroup, GlFormInput, GlSprintf } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { validateName, validateUrl } from '../validations';
import { VALIDATION_FIELD_KEYS } from '../constants';

export default {
  name: 'GeoNodeFormCore',
  components: {
    GlFormGroup,
    GlFormInput,
    GlSprintf,
  },
  props: {
    nodeData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['formErrors']),
  },
  methods: {
    ...mapActions(['setError']),
    checkName() {
      this.setError({ key: VALIDATION_FIELD_KEYS.NAME, error: validateName(this.nodeData.name) });
    },
    checkUrl() {
      this.setError({ key: VALIDATION_FIELD_KEYS.URL, error: validateUrl(this.nodeData.url) });
    },
  },
};
</script>

<template>
  <section class="form-row">
    <gl-form-group
      class="col-sm-6"
      :label="__('Name')"
      label-for="node-name-field"
      :state="Boolean(formErrors.name)"
      :invalid-feedback="formErrors.name"
    >
      <template #description>
        <gl-sprintf
          :message="
            __(
              'The unique identifier for the Geo node. Must match %{geoNodeName} if it is set in gitlab.rb, otherwise it must match %{externalUrl} with a trailing slash',
            )
          "
        >
          <template #geoNodeName>
            <code>{{ __('geo_node_name') }}</code>
          </template>
          <template #externalUrl>
            <code>{{ __('external_url') }}</code>
          </template>
        </gl-sprintf>
      </template>
      <gl-form-input
        id="node-name-field"
        v-model="nodeData.name"
        :class="{ 'is-invalid': Boolean(formErrors.name) }"
        data-qa-selector="node_name_field"
        type="text"
        @input="checkName"
      />
    </gl-form-group>
    <gl-form-group
      class="col-sm-6"
      :label="__('URL')"
      label-for="node-url-field"
      :description="__('The user-facing URL of the Geo node')"
      :state="Boolean(formErrors.url)"
      :invalid-feedback="formErrors.url"
    >
      <gl-form-input
        id="node-url-field"
        v-model="nodeData.url"
        :class="{ 'is-invalid': Boolean(formErrors.url) }"
        data-qa-selector="node_url_field"
        type="text"
        @input="checkUrl"
      />
    </gl-form-group>
  </section>
</template>
