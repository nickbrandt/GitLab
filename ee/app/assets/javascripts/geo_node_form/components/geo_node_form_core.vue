<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';

export default {
  name: 'GeoNodeFormCore',
  components: {
    GlFormGroup,
    GlFormInput,
  },
  props: {
    nodeData: {
      type: Object,
      required: true,
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
      :description="
        __(
          'The unique identifier for the Geo node. Must match `geo_node_name` if it is set in gitlab.rb, otherwise it must match `external_url` with a trailing slash',
        )
      "
    >
      <gl-form-input id="node-name-field" v-model="nodeData.name" type="text" />
    </gl-form-group>
    <gl-form-group
      class="col-sm-6"
      :label="__('URL')"
      label-for="node-url-field"
      :description="__('The user-facing URL of the Geo node')"
    >
      <gl-form-input id="node-url-field" v-model="nodeData.url" type="text" />
    </gl-form-group>
  </section>
</template>
