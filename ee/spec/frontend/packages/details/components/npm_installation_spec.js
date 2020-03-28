import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import NpmInstallation from 'ee/packages/details/components/npm_installation.vue';
import { TrackingActions, TrackingLabels } from 'ee/packages/details/constants';
import { npmPackage as packageEntity } from '../../mock_data';
import { registryUrl as nugetPath } from '../mock_data';
import Tracking from '~/tracking';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('NpmInstallation', () => {
  let wrapper;

  const npmCommandStr = 'npm install';
  const npmSetupStr = 'npm setup';
  const yarnCommandStr = 'npm install';
  const yarnSetupStr = 'npm setup';

  const installationTab = () => wrapper.find('.js-installation-tab > a');
  const setupTab = () => wrapper.find('.js-setup-tab > a');
  const npmInstallationCommand = () => wrapper.find('.js-npm-install > input');
  const npmSetupCommand = () => wrapper.find('.js-npm-setup > input');
  const yarnInstallationCommand = () => wrapper.find('.js-yarn-install > input');
  const yarnSetupCommand = () => wrapper.find('.js-yarn-setup > input');

  function createComponent(yarn = false) {
    const store = new Vuex.Store({
      state: {
        packageEntity,
        nugetPath,
      },
      getters: {
        npmInstallationCommand: () => () => (yarn ? yarnCommandStr : npmCommandStr),
        npmSetupCommand: () => () => (yarn ? yarnSetupStr : npmSetupStr),
      },
    });

    wrapper = mount(NpmInstallation, {
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

  describe('npm commands', () => {
    it('renders the correct install command', () => {
      expect(npmInstallationCommand().element.value).toBe(npmCommandStr);
    });

    it('renders the correct setup command', () => {
      expect(npmSetupCommand().element.value).toBe(npmSetupStr);
    });
  });

  describe('yarn commands', () => {
    beforeEach(() => {
      createComponent(true);
    });

    it('renders the correct install command', () => {
      expect(yarnInstallationCommand().element.value).toBe(yarnCommandStr);
    });

    it('renders the correct setup command', () => {
      expect(yarnSetupCommand().element.value).toBe(yarnSetupStr);
    });
  });

  describe('tab change tracking', () => {
    let eventSpy;
    const label = TrackingLabels.NPM_INSTALLATION;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      createComponent();
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
