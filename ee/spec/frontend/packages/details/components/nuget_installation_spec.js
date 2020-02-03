import { mount } from '@vue/test-utils';
import NugetInstallation from 'ee/packages/details/components/nuget_installation.vue';
import { nugetPackage } from '../../mock_data';
import { registryUrl } from '../mock_data';
import { TrackingActions, TrackingLabels } from 'ee/packages/details/constants';
import Tracking from '~/tracking';

describe('NugetInstallation', () => {
  let wrapper;

  const defaultProps = {
    packageEntity: nugetPackage,
    registryUrl,
    helpUrl: 'foo',
  };

  const nugetInstallationCommandStr = `nuget install ${nugetPackage.name} -Source "GitLab"`;
  const nugetSetupCommandStr = `nuget source Add -Name "GitLab" -Source "${registryUrl}" -UserName <your_username> -Password <your_token>`;

  const installationTab = () => wrapper.find('.js-installation-tab > a');
  const setupTab = () => wrapper.find('.js-setup-tab > a');
  const nugetInstallationCommand = () => wrapper.find('.js-nuget-command > input');
  const nugetSetupCommand = () => wrapper.find('.js-nuget-setup > input');

  function createComponent(props = {}) {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    wrapper = mount(NugetInstallation, {
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
