import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import DeleteEnvironmentModal from '~/environments/components/delete_environment_modal.vue';
import EnvironmentsDetailHeader from '~/environments/components/environments_detail_header.vue';
import StopEnvironmentModal from '~/environments/components/stop_environment_modal.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Environments detail header component', () => {
  const cancelAutoStopPath = '/my-environment/cancel/path';
  const terminalPath = '/my-environment/terminal/path';
  const metricsPath = '/my-environment/metrics/path';
  const updatePath = '/my-environment/edit/path';

  const createEnvironment = (data = {}) => ({
    id: 1,
    name: 'My environment',
    externalUrl: 'my external url',
    isAvailable: true,
    hasTerminals: false,
    autoStopAt: null,
    ...data,
  });

  let wrapper;

  const findHeader = () => wrapper.find('h3');
  const findAutoStopsAt = () => wrapper.findByTestId('auto-stops-at');
  const findCancelAutoStopAtButton = () => wrapper.findByTestId('cancel-auto-stop-button');
  const findTerminalButton = () => wrapper.findByTestId('terminal-button');
  const findExternalUrlButton = () => wrapper.findByTestId('external-url-button');
  const findMetricsButton = () => wrapper.findByTestId('metrics-button');
  const findEditButton = () => wrapper.findByTestId('edit-button');
  const findStopButton = () => wrapper.findByTestId('stop-button');
  const findDestroyButton = () => wrapper.findByTestId('destroy-button');
  const findStopEnvironmentModal = () => wrapper.findComponent(StopEnvironmentModal);
  const findDeleteEnvironmentModal = () => wrapper.findComponent(DeleteEnvironmentModal);

  const buttons = [
    ['Cancel Auto Stop At', findCancelAutoStopAtButton],
    ['Terminal', findTerminalButton],
    ['External Url', findExternalUrlButton],
    ['Metrics', findMetricsButton],
    ['Edit', findEditButton],
    ['Stop', findStopButton],
    ['Destroy', findDestroyButton],
  ];

  const createWrapper = ({ props }) => {
    wrapper = extendedWrapper(
      shallowMount(EnvironmentsDetailHeader, {
        stubs: {
          GlSprintf,
          TimeAgo,
        },
        propsData: {
          canReadEnvironment: false,
          canAdminEnvironment: false,
          canUpdateEnvironment: false,
          canStopEnvironment: false,
          canDestroyEnvironment: false,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default state with minimal access', () => {
    beforeEach(() => {
      createWrapper({ props: { environment: createEnvironment() } });
    });

    it('displays the environment name', () => {
      expect(findHeader().text()).toBe('My environment');
    });

    it('does not display an auto stops at text', () => {
      expect(findAutoStopsAt().exists()).toBe(false);
    });

    it.each(buttons)('does not display button: %s', (_, findSelector) => {
      expect(findSelector().exists()).toBe(false);
    });

    it('does not display stop environment modal', () => {
      expect(findStopEnvironmentModal().exists()).toBe(false);
    });

    it('does not display delete environment modal', () => {
      expect(findDeleteEnvironmentModal().exists()).toBe(false);
    });
  });

  describe('when auto stops at is enabled', () => {
    beforeEach(() => {
      const now = new Date();
      const tomorrow = new Date();
      tomorrow.setDate(now.getDate() + 1);
      createWrapper({
        props: {
          environment: createEnvironment({ autoStopAt: tomorrow.toISOString(), isAvailable: true }),
          cancelAutoStopPath,
        },
      });
    });

    it('displays a text that describes when the environment is going to be stopped', () => {
      expect(findAutoStopsAt().text()).toBe('Auto stops in 1 day');
    });

    it('displays a cancel auto stops at button with correct path', () => {
      expect(findCancelAutoStopAtButton().attributes('href')).toBe(cancelAutoStopPath);
    });
  });

  describe('when has a terminal', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          environment: createEnvironment({ hasTerminals: true }),
          canAdminEnvironment: true,
          terminalPath,
        },
      });
    });

    it('displays the terminal button with correct path', () => {
      expect(findTerminalButton().attributes('href')).toBe(terminalPath);
    });
  });

  describe('when has an external url enabled', () => {
    const externalUrl = 'https://example.com/my-environment/external/url';

    beforeEach(() => {
      createWrapper({
        props: {
          environment: createEnvironment({ hasTerminals: true, externalUrl }),
          canReadEnvironment: true,
        },
      });
    });

    it('displays the external url button with correct path', () => {
      expect(findExternalUrlButton().attributes('href')).toBe(externalUrl);
    });
  });

  describe('when metrics are enabled', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          environment: createEnvironment(),
          canReadEnvironment: true,
          metricsPath,
        },
      });
    });

    it('displays the metrics button with correct path', () => {
      expect(findMetricsButton().attributes('href')).toBe(metricsPath);
    });
  });

  describe('when has all admin rights', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          environment: createEnvironment(),
          canReadEnvironment: true,
          canAdminEnvironment: true,
          canStopEnvironment: true,
          canUpdateEnvironment: true,
          updatePath,
        },
      });
    });

    it('displays the edit button with correct path', () => {
      expect(findEditButton().attributes('href')).toBe(updatePath);
    });

    it('displays the stop button with correct icon', () => {
      expect(findStopButton().attributes('icon')).toBe('stop');
    });

    it('displays stop environment modal', () => {
      expect(findStopEnvironmentModal().exists()).toBe(true);
    });
  });

  describe('when the environment is unavailable and user has destroy permissions', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          environment: createEnvironment({ isAvailable: false }),
          canDestroyEnvironment: true,
        },
      });
    });

    it('displays a delete button', () => {
      expect(findDestroyButton().exists()).toBe(true);
    });

    it('displays delete environment modal', () => {
      expect(findDeleteEnvironmentModal().exists()).toBe(true);
    });
  });
});
