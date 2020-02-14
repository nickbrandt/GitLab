import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import MavenInstallation from 'ee/packages/details/components/maven_installation.vue';
import { TrackingActions, TrackingLabels } from 'ee/packages/details/constants';
import { registryUrl as mavenPath } from '../mock_data';
import { mavenPackage as packageEntity } from '../../mock_data';
import Tracking from '~/tracking';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('MavenInstallation', () => {
  let wrapper;

  const xmlCodeBlock = 'foo/xml';
  const mavenCommandStr = 'foo/command';
  const mavenSetupXml = 'foo/setup';

  const store = new Vuex.Store({
    state: {
      packageEntity,
      mavenPath,
    },
    getters: {
      mavenInstallationXml: () => xmlCodeBlock,
      mavenInstallationCommand: () => mavenCommandStr,
      mavenSetupXml: () => mavenSetupXml,
    },
  });

  const installationTab = () => wrapper.find('.js-installation-tab > a');
  const setupTab = () => wrapper.find('.js-setup-tab > a');
  const xmlCode = () => wrapper.find('.js-maven-xml > pre');
  const mavenCommand = () => wrapper.find('.js-maven-command > input');
  const xmlSetup = () => wrapper.find('.js-maven-setup-xml > pre');

  function createComponent() {
    wrapper = mount(MavenInstallation, {
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
    it('renders the correct xml block', () => {
      expect(xmlCode().text()).toBe(xmlCodeBlock);
    });

    it('renders the correct maven command', () => {
      expect(mavenCommand().element.value).toBe(mavenCommandStr);
    });
  });

  describe('setup commands', () => {
    it('renders the correct xml block', () => {
      expect(xmlSetup().text()).toBe(mavenSetupXml);
    });
  });

  describe('tab change tracking', () => {
    let eventSpy;
    const label = TrackingLabels.MAVEN_INSTALLATION;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
    });

    it('should track when the setup tab is clicked', () => {
      setupTab().trigger('click');

      return wrapper.vm.$nextTick(() => {
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
