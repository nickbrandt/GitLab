import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import ConanInstallation from 'ee/packages/details/components/conan_installation.vue';
import { conanPackage as packageEntity } from '../../mock_data';
import { registryUrl as conanPath } from '../mock_data';
import { TrackingActions, TrackingLabels } from 'ee/packages/details/constants';
import Tracking from '~/tracking';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ConanInstallation', () => {
  let wrapper;

  const conanInstallationCommandStr = 'foo/command';
  const conanSetupCommandStr = 'foo/setup';

  const store = new Vuex.Store({
    state: {
      packageEntity,
      conanPath,
    },
    getters: {
      conanInstallationCommand: () => conanInstallationCommandStr,
      conanSetupCommand: () => conanSetupCommandStr,
    },
  });

  const installationTab = () => wrapper.find('.js-installation-tab > a');
  const setupTab = () => wrapper.find('.js-setup-tab > a');
  const conanInstallationCommand = () => wrapper.find('.js-conan-command > input');
  const conanSetupCommand = () => wrapper.find('.js-conan-setup > input');

  function createComponent() {
    wrapper = mount(ConanInstallation, {
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
      expect(conanInstallationCommand().element.value).toBe(conanInstallationCommandStr);
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(conanSetupCommand().element.value).toBe(conanSetupCommandStr);
    });
  });

  describe('tab change tracking', () => {
    let eventSpy;
    const label = TrackingLabels.CONAN_INSTALLATION;

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
        })
        .then(() => {
          expect(eventSpy).toHaveBeenCalledWith(undefined, TrackingActions.INSTALLATION, {
            label,
          });
        });
    });
  });
});
