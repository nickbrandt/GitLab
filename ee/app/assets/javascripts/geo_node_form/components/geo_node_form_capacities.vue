<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';

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
  data() {
    return {
      formGroups: [
        {
          id: 'node-repository-capacity-field',
          label: __('Repository sync capacity'),
          description: __(
            'Control the maximum concurrency of repository backfill for this secondary node',
          ),
          key: 'reposMaxCapacity',
          conditional: 'secondary',
        },
        {
          id: 'node-file-capacity-field',
          label: __('File sync capacity'),
          description: __(
            'Control the maximum concurrency of LFS/attachment backfill for this secondary node',
          ),
          key: 'filesMaxCapacity',
          conditional: 'secondary',
        },
        {
          id: 'node-verification-capacity-field',
          label: __('Verification capacity'),
          description: __(
            'Control the maximum concurrency of verification operations for this Geo node',
          ),
          key: 'verificationMaxCapacity',
        },
        {
          id: 'node-container-repository-capacity-field',
          label: __('Container repositories sync capacity'),
          description: __(
            'Control the maximum concurrency of container repository operations for this Geo node',
          ),
          key: 'containerRepositoriesMaxCapacity',
        },
        {
          id: 'node-reverification-interval-field',
          label: __('Re-verification interval'),
          description: __(
            'Control the minimum interval in days that a repository should be reverified for this primary node',
          ),
          key: 'minimumReverificationInterval',
          conditional: 'primary',
        },
      ],
    };
  },
  computed: {
    visibleFormGroups() {
      return this.formGroups.filter(group => {
        if (group.conditional) {
          return this.nodeData.primary
            ? group.conditional === 'primary'
            : group.conditional === 'secondary';
        }
        return true;
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group
      v-for="formGroup in visibleFormGroups"
      :key="formGroup.id"
      :label="formGroup.label"
      :label-for="formGroup.id"
      :description="formGroup.description"
    >
      <gl-form-input
        :id="formGroup.id"
        v-model="nodeData[formGroup.key]"
        class="col-sm-3"
        type="number"
      />
    </gl-form-group>
  </div>
</template>
