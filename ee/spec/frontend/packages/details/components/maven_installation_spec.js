import { mount } from '@vue/test-utils';
import MavenInstallation from 'ee/packages/details/components/maven_installation.vue';
import {
  generateMavenCommand,
  generateXmlCodeBlock,
  generateMavenSetupXml,
  mavenMetadata,
  registryUrl,
} from '../mock_data';

describe('MavenInstallation', () => {
  let wrapper;

  const defaultProps = {
    mavenMetadata,
    registryUrl,
    helpUrl: 'foo',
  };

  const mavenCommandStr = generateMavenCommand(mavenMetadata);
  const xmlCodeBlock = generateXmlCodeBlock(mavenMetadata);
  const mavenSetupXml = generateMavenSetupXml();

  const xmlCode = () => wrapper.find('.js-maven-xml > pre');
  const mavenCommand = () => wrapper.find('.js-maven-command > input');
  const xmlSetup = () => wrapper.find('.js-maven-setup-xml > pre');

  function createComponent(props = {}) {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    wrapper = mount(MavenInstallation, {
      propsData,
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    if (wrapper) wrapper.destroy();
  });

  describe('with empty maven metadata', () => {
    beforeEach(() => {
      createComponent({
        mavenMetadata: {},
      });
    });

    it('renders empty strings in the xml block', () => {
      const emptyXmlBlock = generateXmlCodeBlock({});

      expect(xmlCode().text()).toBe(emptyXmlBlock);
    });

    it('renders empty strings in the command block', () => {
      const emptyMavenCommand = generateMavenCommand({});

      expect(mavenCommand().element.value).toBe(emptyMavenCommand);
    });
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
});
