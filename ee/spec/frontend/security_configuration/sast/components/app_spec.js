import { shallowMount } from '@vue/test-utils';
import { GlLink, GlSprintf } from '@gitlab/ui';
import SASTConfigurationApp from 'ee/security_configuration/sast/components/app.vue';

const sastDocumentationPath = '/help/sast';

describe('SAST Configuration App', () => {
  let wrapper;

  const createComponent = ({ props = {}, stubs = {} } = {}) => {
    wrapper = shallowMount(SASTConfigurationApp, {
      stubs,
      propsData: {
        ...props,
      },
    });
  };

  const findHeader = () => wrapper.find('header');
  const findSubHeading = () => findHeader().find('p');
  const findLink = (container = wrapper) => container.find(GlLink);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('header', () => {
    beforeEach(() => {
      createComponent({
        props: { sastDocumentationPath },
        stubs: { GlSprintf },
      });
    });

    it('displays a link to sastDocumentationPath', () => {
      expect(findLink(findHeader()).attributes('href')).toBe(sastDocumentationPath);
    });

    it('displays the subheading', () => {
      expect(findSubHeading().text()).toMatchInterpolatedText(SASTConfigurationApp.helpText);
    });
  });
});
