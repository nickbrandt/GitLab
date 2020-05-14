<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { timeRanges, defaultTimeRange } from '~/vue_shared/constants';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';

export default {
  name: 'ThreatMonitoringFilters',
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
    DateTimePicker,
  },
  data() {
    return {
      selectedTimeRange: defaultTimeRange,
      timeRanges,
    };
  },
  computed: {
    ...mapState('threatMonitoring', [
      'environments',
      'currentEnvironmentId',
      'isLoadingEnvironments',
      'isLoadingWafStatistics',
    ]),
    ...mapGetters('threatMonitoring', ['currentEnvironmentName']),
    isDisabled() {
      return (
        this.isLoadingEnvironments || this.isLoadingWafStatistics || this.environments.length === 0
      );
    },
  },
  methods: {
    ...mapActions('threatMonitoring', ['setCurrentEnvironmentId', 'setCurrentTimeWindow']),
    onDateTimePickerInput(timeRange) {
      this.selectedTimeRange = timeRange;
      this.setCurrentTimeWindow(timeRange);
    },
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
          ref="environmentsDropdown"
          class="mb-0 d-flex"
          toggle-class="d-flex justify-content-between text-truncate"
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
        label-for="threat-monitoring-time-window-dropdown"
        class="col-sm-6 col-md-6 col-lg-4"
      >
        <date-time-picker
          ref="dateTimePicker"
          :custom-enabled="false"
          :value="selectedTimeRange"
          :options="timeRanges"
          :disabled="isDisabled"
          @input="onDateTimePickerInput"
        />
      </gl-form-group>
    </div>
  </div>
</template>
