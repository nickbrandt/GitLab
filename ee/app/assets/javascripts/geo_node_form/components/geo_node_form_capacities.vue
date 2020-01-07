<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';

export default {
  name: 'GeoNodeFormCapacities',
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
  <div>
    <gl-form-group
      v-if="!nodeData.primary"
      :label="__('Repository sync capacity')"
      label-for="node-repository-capacity-field"
      :description="
        __('Control the maximum concurrency of repository backfill for this secondary node')
      "
    >
      <gl-form-input
        id="node-repository-capacity-field"
        v-model="nodeData.reposMaxCapacity"
        class="col-sm-3"
        type="number"
      />
    </gl-form-group>
    <gl-form-group
      v-if="!nodeData.primary"
      :label="__('File sync capacity')"
      label-for="node-file-capacity-field"
      :description="
        __('Control the maximum concurrency of LFS/attachment backfill for this secondary node')
      "
    >
      <gl-form-input
        id="node-file-capacity-field"
        v-model="nodeData.filesMaxCapacity"
        class="col-sm-3"
        type="number"
      />
    </gl-form-group>
    <gl-form-group
      :label="__('Verification capacity')"
      label-for="node-verification-capacity-field"
      :description="
        __('Control the maximum concurrency of verification operations for this Geo node')
      "
    >
      <gl-form-input
        id="node-verification-capacity-field"
        v-model="nodeData.verificationMaxCapacity"
        class="col-sm-3"
        type="number"
      />
    </gl-form-group>
    <gl-form-group
      :label="__('Container repositories sync capacity')"
      label-for="node-container-repository-capacity-field"
      :description="
        __('Control the maximum concurrency of container repository operations for this Geo node')
      "
    >
      <gl-form-input
        id="node-container-repository-capacity-field"
        v-model="nodeData.containerRepositoriesMaxCapacity"
        class="col-sm-3"
        type="number"
      />
    </gl-form-group>
    <gl-form-group
      v-if="nodeData.primary"
      :label="__('Re-verification interval')"
      label-for="node-reverification-interval-field"
      :description="
        __(
          'Control the minimum interval in days that a repository should be reverified for this primary node',
        )
      "
    >
      <gl-form-input
        id="node-reverification-interval-field"
        v-model="nodeData.minimumReverificationInterval"
        class="col-sm-3"
        type="number"
      />
    </gl-form-group>
  </div>
</template>
