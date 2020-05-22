<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import { validateCapacity } from '../validations';
import { VALIDATION_FIELD_KEYS } from '../constants';

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
          key: VALIDATION_FIELD_KEYS.REPOS_MAX_CAPACITY,
          conditional: 'secondary',
        },
        {
          id: 'node-file-capacity-field',
          label: __('File sync capacity'),
          description: __(
            'Control the maximum concurrency of LFS/attachment backfill for this secondary node',
          ),
          key: VALIDATION_FIELD_KEYS.FILES_MAX_CAPACITY,
          conditional: 'secondary',
        },
        {
          id: 'node-container-repository-capacity-field',
          label: __('Container repositories sync capacity'),
          description: __(
            'Control the maximum concurrency of container repository operations for this Geo node',
          ),
          key: VALIDATION_FIELD_KEYS.CONTAINER_REPOSITORIES_MAX_CAPACITY,
          conditional: 'secondary',
        },
        {
          id: 'node-verification-capacity-field',
          label: __('Verification capacity'),
          description: __(
            'Control the maximum concurrency of verification operations for this Geo node',
          ),
          key: VALIDATION_FIELD_KEYS.VERIFICATION_MAX_CAPACITY,
        },
        {
          id: 'node-reverification-interval-field',
          label: __('Re-verification interval'),
          description: __(
            'Control the minimum interval in days that a repository should be reverified for this primary node',
          ),
          key: VALIDATION_FIELD_KEYS.MINIMUM_REVERIFICATION_INTERVAL,
          conditional: 'primary',
        },
      ],
    };
  },
  computed: {
    ...mapState(['formErrors']),
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
  methods: {
    ...mapActions(['setError']),
    checkCapacity(formGroup) {
      this.setError({
        key: formGroup.key,
        error: validateCapacity({ data: this.nodeData[formGroup.key], label: formGroup.label }),
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
      :state="Boolean(formErrors[formGroup.key])"
      :invalid-feedback="formErrors[formGroup.key]"
    >
      <gl-form-input
        :id="formGroup.id"
        v-model="nodeData[formGroup.key]"
        :class="{ 'is-invalid': Boolean(formErrors[formGroup.key]) }"
        class="col-sm-3"
        type="number"
        @input="checkCapacity(formGroup)"
      />
    </gl-form-group>
  </div>
</template>
