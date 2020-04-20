import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import ConanInstallation from 'ee/packages/details/components/conan_installation.vue';
import { conanPackage as packageEntity } from '../../mock_data';
import { registryUrl as conanPath } from '../mock_data';

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
});
