import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import createStore from 'ee/threat_monitoring/store';
import ThreatMonitoringFilters from 'ee/threat_monitoring/components/threat_monitoring_filters.vue';
import { INVALID_CURRENT_ENVIRONMENT_NAME } from 'ee/threat_monitoring/store/modules/threat_monitoring/constants';
import { mockEnvironmentsResponse } from '../mock_data';

const localVue = createLocalVue();

describe('ThreatMonitoringFilters component', () => {
  let store;
  let wrapper;

  const factory = state => {
    store = createStore();
    Object.assign(store.state.threatMonitoring, state);

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(ThreatMonitoringFilters, {
      localVue,
      store,
      sync: false,
    });
  };

  const findEnvironmentsDropdown = () => wrapper.find(GlDropdown);
  const findEnvironmentsDropdownItems = () => wrapper.findAll(GlDropdownItem).wrappers;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('given there are no environments', () => {
    beforeEach(() => {
      factory();
    });

    describe('the environments dropdown', () => {
      it('is disabled', () => {
        expect(findEnvironmentsDropdown().attributes().disabled).toBe('true');
      });

      it('has text set to the INVALID_CURRENT_ENVIRONMENT_NAME', () => {
        expect(findEnvironmentsDropdown().attributes().text).toBe(INVALID_CURRENT_ENVIRONMENT_NAME);
      });

      it('has no dropdown items', () => {
        expect(findEnvironmentsDropdownItems()).toHaveLength(0);
      });
    });
  });

  describe('given there are environments', () => {
    const { environments } = mockEnvironmentsResponse;
    const currentEnvironment = environments[1];

    beforeEach(() => {
      factory({
        environments,
        currentEnvironmentId: currentEnvironment.id,
      });
    });

    describe('the environments dropdown', () => {
      it('is not disabled', () => {
        expect(findEnvironmentsDropdown().attributes().disabled).toBe(undefined);
      });

      it('has text set to the current environment', () => {
        expect(findEnvironmentsDropdown().attributes().text).toBe(currentEnvironment.name);
      });

      it('has dropdown items for each environment', () => {
        const dropdownItems = findEnvironmentsDropdownItems();

        environments.forEach((environment, i) => {
          expect(dropdownItems[i].text()).toBe(environment.name);

          dropdownItems[i].vm.$emit('click');
          expect(store.dispatch).toHaveBeenCalledWith(
            'threatMonitoring/setCurrentEnvironmentId',
            environment.id,
          );
        });
      });
    });
  });
});
