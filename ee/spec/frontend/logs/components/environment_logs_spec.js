import Vue from 'vue';
import { GlDropdown, GlButton, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import {
  canScroll,
  isScrolledToTop,
  isScrolledToBottom,
  scrollDown,
  scrollUp,
} from '~/lib/utils/scroll_utils';
import EnvironmentLogs from 'ee/logs/components/environment_logs.vue';
import { createStore } from 'ee/logs/stores';
import {
  mockEnvironment,
  mockEnvironments,
  mockPods,
  mockEnvironmentsEndpoint,
  mockLines,
  mockLogsEndpoint,
} from '../mock_data';

jest.mock('~/lib/utils/scroll_utils');

describe('EnvironmentLogs', () => {
  let EnvironmentLogsComponent;
  let store;
  let wrapper;
  let state;

  const propsData = {
    currentEnvironmentName: mockEnvironment.name,
    environmentsPath: mockEnvironmentsEndpoint,
    logsEndpoint: mockLogsEndpoint,
  };
  const actionMocks = {
    fetchEnvironments: jest.fn(),
    fetchLogs: jest.fn(),
  };

  const findEnvironmentsDropdown = () => wrapper.find('.js-environments-dropdown');
  const findPodsDropdown = () => wrapper.find('.js-pods-dropdown');
  const findScrollToTop = () => wrapper.find('.js-scroll-to-top');
  const findScrollToBottom = () => wrapper.find('.js-scroll-to-bottom');
  const findRefreshLog = () => wrapper.find('.js-refresh-log');
  const findLogTrace = () => wrapper.find('.js-log-trace');

  const initWrapper = () => {
    wrapper = shallowMount(EnvironmentLogsComponent, {
      propsData,
      store,
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

  it('displays UI elements', () => {
    initWrapper();

    expect(wrapper.isVueInstance()).toBe(true);
    expect(wrapper.isEmpty()).toBe(false);

    expect(findEnvironmentsDropdown().is(GlDropdown)).toBe(true);
    expect(findPodsDropdown().is(GlDropdown)).toBe(true);

    expect(findScrollToTop().is(GlButton)).toBe(true);
    expect(findScrollToBottom().is(GlButton)).toBe(true);
    expect(findRefreshLog().is(GlButton)).toBe(true);

    expect(findLogTrace().isEmpty()).toBe(false);
  });

  describe('loading state', () => {
    beforeEach(() => {
      actionMocks.fetchEnvironments.mockImplementation(() => {
        state.environments.options = [];
        state.environments.isLoading = true;
      });
      actionMocks.fetchLogs.mockImplementation(() => {
        state.pods.options = [];
        state.logs.lines = [];
        state.logs.isLoading = true;
      });

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

    it('shows a logs trace', () => {
      const trace = findLogTrace();
      expect(trace.text()).toBe('');
      expect(trace.find('.js-build-loader-animation').isVisible()).toBe(true);
    });
  });

  describe('state with data', () => {
    beforeEach(() => {
      actionMocks.fetchEnvironments.mockImplementation(() => {
        state.environments.options = mockEnvironments;
      });
      actionMocks.fetchLogs.mockImplementation(() => {
        state.pods.options = mockPods;
        [state.pods.current] = state.pods.options;

        state.logs.isComplete = false;
        state.logs.lines = mockLines;
      });

      initWrapper();
    });

    afterEach(() => {
      scrollDown.mockReset();
      scrollUp.mockReset();

      actionMocks.fetchEnvironments.mockReset();
      actionMocks.fetchLogs.mockReset();
    });

    it('populates environments dropdown', () => {
      const items = findEnvironmentsDropdown().findAll(GlDropdownItem);

      expect(items.length).toBe(mockEnvironments.length);
      mockEnvironments.forEach((env, i) => {
        const item = items.at(i);

        expect(item.text()).toBe(env.name);
        expect(item.attributes('href')).toBe(env.logs_path);
      });
    });

    it('populates pods dropdown', () => {
      const items = findPodsDropdown().findAll(GlDropdownItem);

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

    it('scrolls to bottom when loaded', () => {
      expect(scrollDown).toHaveBeenCalledTimes(1);
    });

    describe('when user clicks', () => {
      it('pod name, trace is refreshed', () => {
        const items = findPodsDropdown().findAll(GlDropdownItem);
        const index = 2; // any pod

        expect(actionMocks.fetchLogs).toHaveBeenCalledTimes(1);
        expect(actionMocks.fetchLogs).toHaveBeenLastCalledWith(null);

        items.at(index).vm.$emit('click');

        expect(actionMocks.fetchLogs).toHaveBeenCalledTimes(2);
        expect(actionMocks.fetchLogs).toHaveBeenLastCalledWith(mockPods[index]);
      });

      it('refresh button, trace is refreshed', () => {
        expect(actionMocks.fetchLogs).toHaveBeenCalledTimes(1);
        expect(actionMocks.fetchLogs).toHaveBeenLastCalledWith(null);

        findRefreshLog().vm.$emit('click'); // works

        expect(actionMocks.fetchLogs).toHaveBeenCalledTimes(2);
        expect(actionMocks.fetchLogs).toHaveBeenLastCalledWith(mockPods[0]);
      });

      describe('when scrolling actions are enabled', () => {
        beforeEach(done => {
          // simulate being in the middle of a long page
          canScroll.mockReturnValue(true);
          isScrolledToBottom.mockReturnValue(false);
          isScrolledToTop.mockReturnValue(false);

          initWrapper();
          wrapper.vm.updateScrollState();
          wrapper.vm.$nextTick(done);
        });

        afterEach(() => {
          canScroll.mockReset();
          isScrolledToTop.mockReset();
          isScrolledToBottom.mockReset();
        });

        it('click on "scroll to top" scrolls up', () => {
          expect(findScrollToTop().is('[disabled]')).toBe(false);
          findScrollToTop().vm.$emit('click');
          expect(scrollUp).toHaveBeenCalledTimes(1);
        });

        it('click on "scroll to bottom" scrolls down', () => {
          expect(findScrollToBottom().is('[disabled]')).toBe(false);
          findScrollToBottom().vm.$emit('click');
          expect(scrollDown).toHaveBeenCalledTimes(2); // plus one time when loaded
        });
      });

      describe('when scrolling actions are disabled', () => {
        beforeEach(() => {
          // a short page, without a scrollbar
          canScroll.mockReturnValue(false);
          isScrolledToBottom.mockReturnValue(true);
          isScrolledToTop.mockReturnValue(true);

          initWrapper();
        });

        it('buttons are disabled', done => {
          wrapper.vm.updateScrollState();
          wrapper.vm.$nextTick(() => {
            expect(findScrollToTop().is('[disabled]')).toBe(true);
            expect(findScrollToBottom().is('[disabled]')).toBe(true);
            done();
          });
        });
      });
    });
  });
});
