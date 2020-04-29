import { shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlFormInput } from '@gitlab/ui';
import VariablesSection from '~/monitoring/components/variables_section.vue';
import { updateHistory, mergeUrlParams } from '~/lib/utils/url_utility';
import { createStore } from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';

jest.mock('~/lib/utils/url_utility', () => ({
  updateHistory: jest.fn(),
  mergeUrlParams: jest.fn(),
}));

describe('Metrics dashboard/variables section component', () => {
  let store;
  let wrapper;
  const sampleVariables = {
    label1: 'pod',
    label2: 'main',
  };

  const createShallowWrapper = () => {
    wrapper = shallowMount(VariablesSection, {
      store,
    });
  };

  const findAllFormInputs = () => wrapper.findAll(GlFormInput);
  const getInputAt = i => findAllFormInputs().at(i);

  beforeEach(() => {
    store = createStore();

    store.state.monitoringDashboard.showEmptyState = false;
  });

  it('does not show the variables section', () => {
    createShallowWrapper();
    const allInputs = findAllFormInputs();

    expect(allInputs).toHaveLength(0);
  });

  it('shows the variables section', () => {
    createShallowWrapper();
    wrapper.vm.$store.commit(
      `monitoringDashboard/${types.SET_PROM_QUERY_VARIABLES}`,
      sampleVariables,
    );

    return wrapper.vm.$nextTick(() => {
      const allInputs = findAllFormInputs();

      expect(allInputs).toHaveLength(Object.keys(sampleVariables).length);
    });
  });

  describe('when changing the variable inputs', () => {
    const fetchDashboardData = jest.fn();

    beforeEach(() => {
      store = new Vuex.Store({
        modules: {
          monitoringDashboard: {
            namespaced: true,
            state: {
              showEmptyState: false,
              promVariables: sampleVariables,
            },
            actions: {
              fetchDashboardData,
            },
          },
        },
      });

      createShallowWrapper();
    });

    it('merges the url params and refreshes the dashboard when a form input is blurred', () => {
      const firstInput = getInputAt(0);

      firstInput.vm.$emit('input');
      firstInput.vm.$emit('blur');

      expect(mergeUrlParams).toHaveBeenCalledWith(sampleVariables, window.location.href);
      expect(updateHistory).toHaveBeenCalled();
      expect(fetchDashboardData).toHaveBeenCalled();
    });

    it('merges the url params and refreshes the dashboard when a form input has received an enter key press', () => {
      const firstInput = getInputAt(0);

      firstInput.vm.$emit('input');
      firstInput.trigger('keyup.enter');

      expect(mergeUrlParams).toHaveBeenCalledWith(sampleVariables, window.location.href);
      expect(updateHistory).toHaveBeenCalled();
      expect(fetchDashboardData).toHaveBeenCalled();
    });
  });
});
