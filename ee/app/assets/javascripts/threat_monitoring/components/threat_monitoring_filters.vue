<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { TIME_WINDOWS } from '../constants';

export default {
  name: 'ThreatMonitoringFilters',
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
  },
  computed: {
    ...mapState('threatMonitoring', [
      'environments',
      'currentEnvironmentId',
      'isLoadingEnvironments',
      'isLoadingWafStatistics',
    ]),
    ...mapGetters('threatMonitoring', ['currentEnvironmentName', 'currentTimeWindowName']),
    isDisabled() {
      return (
        this.isLoadingEnvironments || this.isLoadingWafStatistics || this.environments.length === 0
      );
    },
  },
  methods: {
    ...mapActions('threatMonitoring', ['setCurrentEnvironmentId', 'setCurrentTimeWindow']),
  },
  environmentFilterId: 'threat-monitoring-environment-filter',
  showLastFilterId: 'threat-monitoring-show-last-filter',
  timeWindows: TIME_WINDOWS,
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
          ref="environmentsDropdown"
          class="mb-0 d-flex"
          toggle-class="d-flex justify-content-between"
          :text="currentEnvironmentName"
          :disabled="isDisabled"
        >
          <gl-dropdown-item
            v-for="environment in environments"
            :key="environment.id"
            ref="environmentsDropdownItem"
            @click="setCurrentEnvironmentId(environment.id)"
            >{{ environment.name }}</gl-dropdown-item
          >
        </gl-dropdown>
      </gl-form-group>

      <gl-form-group
        :label="s__('ThreatMonitoring|Show last')"
        label-size="sm"
        :label-for="$options.showLastFilterId"
        class="col-sm-6 col-md-4 col-lg-3 col-xl-2"
      >
        <gl-dropdown
          :id="$options.showLastFilterId"
          ref="showLastDropdown"
          class="mb-0 d-flex"
          toggle-class="d-flex justify-content-between"
          :text="currentTimeWindowName"
          :disabled="isDisabled"
        >
          <gl-dropdown-item
            v-for="(timeWindowConfig, timeWindow) in $options.timeWindows"
            :key="timeWindow"
            ref="showLastDropdownItem"
            @click="setCurrentTimeWindow(timeWindow)"
            >{{ timeWindowConfig.name }}</gl-dropdown-item
          >
        </gl-dropdown>
      </gl-form-group>
    </div>
  </div>
</template>
