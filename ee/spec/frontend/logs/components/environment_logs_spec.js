import Vue from 'vue';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EnvironmentLogs from 'ee/logs/components/environment_logs.vue';

import { createStore } from 'ee/logs/stores';
import { scrollDown } from '~/lib/utils/scroll_utils';
import {
  mockProjectPath,
  mockEnvName,
  mockEnvironments,
  mockPods,
  mockLines,
  mockPodName,
  mockEnvironmentsEndpoint,
} from '../mock_data';

jest.mock('~/lib/utils/scroll_utils');

describe('EnvironmentLogs', () => {
  let EnvironmentLogsComponent;
  let store;
  let wrapper;
  let state;

  const propsData = {
    projectFullPath: mockProjectPath,
    environmentName: mockEnvName,
    environmentsPath: mockEnvironmentsEndpoint,
  };

  const actionMocks = {
    setInitData: jest.fn(),
    showPodLogs: jest.fn(),
    showEnvironment: jest.fn(),
    fetchEnvironments: jest.fn(),
  };

  const updateControlBtnsMock = jest.fn();

  const findEnvironmentsDropdown = () => wrapper.find('.js-environments-dropdown');
  const findPodsDropdown = () => wrapper.find('.js-pods-dropdown');
  const findLogControlButtons = () => wrapper.find({ name: 'log-control-buttons-stub' });
  const findLogTrace = () => wrapper.find('.js-log-trace');

  const initWrapper = () => {
    wrapper = shallowMount(EnvironmentLogsComponent, {
      attachToDocument: true,
      sync: false,
      propsData,
      store,
      stubs: {
        LogControlButtons: {
          name: 'log-control-buttons-stub',
          template: '<div/>',
          methods: {
            update: updateControlBtnsMock,
          },
        },
      },
      methods: {
        ...actionMocks,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    state = store.state.environmentLogs;
    EnvironmentLogsComponent = Vue.extend(EnvironmentLogs);
  });

  afterEach(() => {
    actionMocks.setInitData.mockReset();
    actionMocks.showPodLogs.mockReset();
    actionMocks.fetchEnvironments.mockReset();

    if (wrapper) {
      wrapper.destroy();
    }
  });

  it('displays UI elements', () => {
    initWrapper();

    expect(wrapper.isVueInstance()).toBe(true);
    expect(wrapper.isEmpty()).toBe(false);
    expect(findLogTrace().isEmpty()).toBe(false);

    expect(findEnvironmentsDropdown().is(GlDropdown)).toBe(true);
    expect(findPodsDropdown().is(GlDropdown)).toBe(true);

    expect(findLogControlButtons().exists()).toBe(true);
  });

  it('mounted inits data', () => {
    initWrapper();

    expect(actionMocks.setInitData).toHaveBeenCalledTimes(1);
    expect(actionMocks.setInitData).toHaveBeenLastCalledWith({
      projectPath: mockProjectPath,
      environmentName: mockEnvName,
      podName: null,
    });

    expect(actionMocks.fetchEnvironments).toHaveBeenCalledTimes(1);
    expect(actionMocks.fetchEnvironments).toHaveBeenLastCalledWith(mockEnvironmentsEndpoint);
  });

  describe('loading state', () => {
    beforeEach(() => {
      state.pods.options = [];

      state.logs.lines = [];
      state.logs.isLoading = true;

      state.environments.options = [];
      state.environments.isLoading = true;

      initWrapper();
    });

    it('displays a disabled environments dropdown', () => {
      expect(findEnvironmentsDropdown().attributes('disabled')).toEqual('true');
      expect(findEnvironmentsDropdown().findAll(GlDropdownItem).length).toBe(0);
    });

    it('displays a disabled pods dropdown', () => {
      expect(findPodsDropdown().attributes('disabled')).toEqual('true');
      expect(findPodsDropdown().findAll(GlDropdownItem).length).toBe(0);
    });

    it('does not update buttons state', () => {
      expect(updateControlBtnsMock).not.toHaveBeenCalled();
    });

    it('shows a logs trace', () => {
      expect(findLogTrace().text()).toBe('');
      expect(
        findLogTrace()
          .find('.js-build-loader-animation')
          .isVisible(),
      ).toBe(true);
    });
  });

  describe('state with data', () => {
    beforeEach(() => {
      actionMocks.setInitData.mockImplementation(() => {
        state.pods.options = mockPods;
        state.environments.current = mockEnvName;
        [state.pods.current] = state.pods.options;

        state.logs.isComplete = false;
        state.logs.lines = mockLines;
      });
      actionMocks.showPodLogs.mockImplementation(podName => {
        state.pods.options = mockPods;
        [state.pods.current] = podName;

        state.logs.isComplete = false;
        state.logs.lines = mockLines;
      });
      actionMocks.fetchEnvironments.mockImplementation(() => {
        state.environments.options = mockEnvironments;
      });

      initWrapper();
    });

    afterEach(() => {
      scrollDown.mockReset();
      updateControlBtnsMock.mockReset();

      actionMocks.setInitData.mockReset();
      actionMocks.showPodLogs.mockReset();
      actionMocks.fetchEnvironments.mockReset();
    });

    it('populates environments dropdown', () => {
      const items = findEnvironmentsDropdown().findAll(GlDropdownItem);
      expect(findEnvironmentsDropdown().props('text')).toBe(mockEnvName);
      expect(items.length).toBe(mockEnvironments.length);
      mockEnvironments.forEach((env, i) => {
        const item = items.at(i);
        expect(item.text()).toBe(env.name);
      });
    });

    it('populates pods dropdown', () => {
      const items = findPodsDropdown().findAll(GlDropdownItem);

      expect(findPodsDropdown().props('text')).toBe(mockPodName);
      expect(items.length).toBe(mockPods.length);
      mockPods.forEach((pod, i) => {
        const item = items.at(i);
        expect(item.text()).toBe(pod);
      });
    });

    it('populates logs trace', () => {
      const trace = findLogTrace();
      expect(trace.text().split('\n').length).toBe(mockLines.length);
      expect(trace.text().split('\n')).toEqual(mockLines);
    });

    it('update control buttons state', () => {
      expect(updateControlBtnsMock).toHaveBeenCalledTimes(1);
    });

    it('scrolls to bottom when loaded', () => {
      expect(scrollDown).toHaveBeenCalledTimes(1);
    });

    describe('when user clicks', () => {
      it('environment name, trace is refreshed', () => {
        const items = findEnvironmentsDropdown().findAll(GlDropdownItem);
        const index = 1; // any env

        expect(actionMocks.showEnvironment).toHaveBeenCalledTimes(0);

        items.at(index).vm.$emit('click');

        expect(actionMocks.showEnvironment).toHaveBeenCalledTimes(1);
        expect(actionMocks.showEnvironment).toHaveBeenLastCalledWith(mockEnvironments[index].name);
      });

      it('pod name, trace is refreshed', () => {
        const items = findPodsDropdown().findAll(GlDropdownItem);
        const index = 2; // any pod

        expect(actionMocks.showPodLogs).toHaveBeenCalledTimes(0);

        items.at(index).vm.$emit('click');

        expect(actionMocks.showPodLogs).toHaveBeenCalledTimes(1);
        expect(actionMocks.showPodLogs).toHaveBeenLastCalledWith(mockPods[index]);
      });

      it('refresh button, trace is refreshed', () => {
        expect(actionMocks.showPodLogs).toHaveBeenCalledTimes(0);

        findLogControlButtons().vm.$emit('refresh');

        expect(actionMocks.showPodLogs).toHaveBeenCalledTimes(1);
        expect(actionMocks.showPodLogs).toHaveBeenLastCalledWith(mockPodName);
      });
    });
  });
});
