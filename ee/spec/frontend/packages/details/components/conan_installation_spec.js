import { mount } from '@vue/test-utils';
import ConanInstallation from 'ee/packages/details/components/conan_installation.vue';
import { generateConanRecipe } from 'ee/packages/details/utils';
import { conanPackage } from '../../mock_data';
import { registryUrl } from '../mock_data';
import { TrackingActions, TrackingLabels } from 'ee/packages/details/constants';
import Tracking from '~/tracking';

describe('ConanInstallation', () => {
  let wrapper;

  const defaultProps = {
    packageEntity: conanPackage,
    registryUrl,
    helpUrl: 'foo',
  };

  const recipe = generateConanRecipe(conanPackage);
  const conanInstallationCommandStr = `conan install ${recipe} --remote=gitlab`;
  const conanSetupCommandStr = `conan remote add gitlab ${registryUrl}`;

  const installationTab = () => wrapper.find('.js-installation-tab > a');
  const setupTab = () => wrapper.find('.js-setup-tab > a');
  const conanInstallationCommand = () => wrapper.find('.js-conan-command > input');
  const conanSetupCommand = () => wrapper.find('.js-conan-setup > input');

  function createComponent(props = {}) {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    wrapper = mount(ConanInstallation, {
      propsData,
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
