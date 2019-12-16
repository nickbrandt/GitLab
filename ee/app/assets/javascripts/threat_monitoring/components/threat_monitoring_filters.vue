<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  name: 'ThreatMonitoringFilters',
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
  },
  computed: {
    ...mapState('threatMonitoring', ['environments', 'currentEnvironmentId']),
    ...mapGetters('threatMonitoring', ['currentEnvironmentName']),
  },
  methods: {
    ...mapActions('threatMonitoring', ['setCurrentEnvironmentId']),
  },
  environmentFilterId: 'threat-monitoring-environment-filter',
};
</script>

<template>
  <div class="pt-3 px-3 bg-gray-light">
    <div class="row">
      <gl-form-group
        :label="s__('ThreatMonitoring|Environment')"
        label-size="sm"
        :label-for="$options.environmentFilterId"
        class="col-sm-6 col-md-4 col-lg-3 col-xl-2"
      >
        <gl-dropdown
          :id="$options.environmentFilterId"
          class="mb-0 d-flex"
          toggle-class="d-flex justify-content-between"
          :text="currentEnvironmentName"
          :disabled="environments.length === 0"
        >
          <gl-dropdown-item
            v-for="environment in environments"
            :key="environment.id"
            @click="setCurrentEnvironmentId(environment.id)"
            >{{ environment.name }}</gl-dropdown-item
          >
        </gl-dropdown>
      </gl-form-group>
    </div>
  </div>
</template>
