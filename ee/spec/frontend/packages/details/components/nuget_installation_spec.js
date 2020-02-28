import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import NugetInstallation from 'ee/packages/details/components/nuget_installation.vue';
import { nugetPackage as packageEntity } from '../../mock_data';
import { registryUrl as nugetPath } from '../mock_data';
import { TrackingActions, TrackingLabels } from 'ee/packages/details/constants';
import Tracking from '~/tracking';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('NugetInstallation', () => {
  let wrapper;

  const nugetInstallationCommandStr = 'foo/command';
  const nugetSetupCommandStr = 'foo/setup';

  const store = new Vuex.Store({
    state: {
      packageEntity,
      nugetPath,
    },
    getters: {
      nugetInstallationCommand: () => nugetInstallationCommandStr,
      nugetSetupCommand: () => nugetSetupCommandStr,
    },
  });

  const installationTab = () => wrapper.find('.js-installation-tab > a');
  const setupTab = () => wrapper.find('.js-setup-tab > a');
  const nugetInstallationCommand = () => wrapper.find('.js-nuget-command > input');
  const nugetSetupCommand = () => wrapper.find('.js-nuget-setup > input');

  function createComponent() {
    wrapper = mount(NugetInstallation, {
      localVue,
      store,
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    if (wrapper) wrapper.destroy();
  });

  describe('installation commands', () => {
    it('renders the correct command', () => {
      expect(nugetInstallationCommand().element.value).toBe(nugetInstallationCommandStr);
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(nugetSetupCommand().element.value).toBe(nugetSetupCommandStr);
    });
  });

  describe('tab change tracking', () => {
    let eventSpy;
    const label = TrackingLabels.NUGET_INSTALLATION;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
    });

    it('should track when the setup tab is clicked', () => {
      setupTab().trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(eventSpy).toHaveBeenCalledWith(undefined, TrackingActions.REGISTRY_SETUP, {
          label,
        });
      });
    });

    it('should track when the installation tab is clicked', () => {
      setupTab().trigger('click');

      return wrapper.vm
        .$nextTick()
        .then(() => {
          installationTab().trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(eventSpy).toHaveBeenCalledWith(undefined, TrackingActions.INSTALLATION, {
            label,
          });
        });
    });
  });
});
