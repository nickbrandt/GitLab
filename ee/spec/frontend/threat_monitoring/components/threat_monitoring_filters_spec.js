import { shallowMount } from '@vue/test-utils';
import createStore from 'ee/threat_monitoring/store';
import ThreatMonitoringFilters from 'ee/threat_monitoring/components/threat_monitoring_filters.vue';
import { INVALID_CURRENT_ENVIRONMENT_NAME } from 'ee/threat_monitoring/constants';
import { mockEnvironmentsResponse } from '../mock_data';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import { timeRanges, defaultTimeRange } from '~/vue_shared/constants';

const mockEnvironments = mockEnvironmentsResponse.environments;

describe('ThreatMonitoringFilters component', () => {
  let store;
  let wrapper;

  const factory = state => {
    store = createStore();
    Object.assign(store.state.threatMonitoring, state);

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(ThreatMonitoringFilters, {
      store,
    });
  };

  const findEnvironmentsDropdown = () => wrapper.find({ ref: 'environmentsDropdown' });
  const findEnvironmentsDropdownItems = () => wrapper.findAll({ ref: 'environmentsDropdownItem' });
  const findShowLastDropdown = () => wrapper.find(DateTimePicker);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('the environments dropdown', () => {
    describe('given there are no environments', () => {
      beforeEach(() => {
        factory();
      });

      it('has text set to the INVALID_CURRENT_ENVIRONMENT_NAME', () => {
        expect(findEnvironmentsDropdown().attributes().text).toBe(INVALID_CURRENT_ENVIRONMENT_NAME);
      });

      it('has no dropdown items', () => {
        expect(findEnvironmentsDropdownItems()).toHaveLength(0);
      });
    });

    describe('given there are environments', () => {
      const currentEnvironment = mockEnvironments[1];

      beforeEach(() => {
        factory({
          environments: mockEnvironments,
          currentEnvironmentId: currentEnvironment.id,
        });
      });

      it('is not disabled', () => {
        expect(findEnvironmentsDropdown().attributes().disabled).toBe(undefined);
      });

      it('has text set to the current environment', () => {
        expect(findEnvironmentsDropdown().attributes().text).toBe(currentEnvironment.name);
      });

      it('has dropdown items for each environment', () => {
        const dropdownItems = findEnvironmentsDropdownItems();

        mockEnvironments.forEach((environment, i) => {
          const dropdownItem = dropdownItems.at(i);
          expect(dropdownItem.text()).toBe(environment.name);

          dropdownItem.vm.$emit('click');
          expect(store.dispatch).toHaveBeenCalledWith(
            'threatMonitoring/setCurrentEnvironmentId',
            environment.id,
          );
        });
      });
    });
  });

  describe('the "show last" dropdown', () => {
    beforeEach(() => {
      factory({
        environments: mockEnvironments,
      });
    });

    it('is not disabled', () => {
      expect(findShowLastDropdown().attributes().disabled).toBe(undefined);
    });

    it('has text set to the current time window name', () => {
      expect(findShowLastDropdown().vm.value.label).toBe(defaultTimeRange.label);
    });

    it('has dropdown items for each time window', () => {
      const dropdownOptions = findShowLastDropdown().props('options');
      Object.entries(timeRanges).forEach(([index, timeWindow]) => {
        const dropdownOption = dropdownOptions[index];
        expect(dropdownOption.interval).toBe(timeWindow.interval);
        expect(dropdownOption.duration.seconds).toBe(timeWindow.duration.seconds);
      });
    });
  });

  describe.each`
    context                         | isLoadingEnvironments | isLoadingWafStatistics | environments
    ${'environments are loading'}   | ${true}               | ${false}               | ${mockEnvironments}
    ${'WAF statistics are loading'} | ${false}              | ${true}                | ${mockEnvironments}
    ${'there are no environments'}  | ${false}              | ${false}               | ${[]}
  `('given $context', ({ isLoadingEnvironments, isLoadingWafStatistics, environments }) => {
    beforeEach(() => {
      factory({
        environments,
        isLoadingEnvironments,
        isLoadingWafStatistics,
      });

      return wrapper.vm.$nextTick();
    });

    it('disables the environments dropdown', () => {
      expect(findEnvironmentsDropdown().attributes('disabled')).toBe('true');
    });

    it('disables the "show last" dropdown', () => {
      expect(findShowLastDropdown().attributes('disabled')).toBe('true');
    });
  });
});
