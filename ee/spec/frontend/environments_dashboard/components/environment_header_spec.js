import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlLink, GlBadge } from '@gitlab/ui';
import component from 'ee/environments_dashboard/components/dashboard/environment_header.vue';
import Icon from '~/vue_shared/components/icon.vue';
import ReviewAppLink from '~/vue_merge_request_widget/components/review_app_link.vue';

const localVue = createLocalVue();

describe('Environment Header', () => {
  const Component = localVue.extend(component);
  let wrapper;
  let propsData;

  beforeEach(() => {
    propsData = {
      environment: {
        environment_path: '/enivronment/1',
        name: 'staging',
        external_url: 'http://example.com',
      },
    };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders name and link to app', () => {
    beforeEach(() => {
      wrapper = shallowMount(Component, {
        sync: false,
        attachToDocument: true,
        propsData,
        localVue,
      });
    });

    it('renders the environment name', () => {
      expect(wrapper.find('.js-environment-name').text()).toBe(propsData.environment.name);
    });

    it('renders a link to the environment page', () => {
      expect(wrapper.find(GlLink).attributes('href')).toBe(propsData.environment.environment_path);
    });

    it('does not show a badge with the number of environments in the folder', () => {
      expect(wrapper.find(GlBadge).exists()).toBe(false);
    });

    it('renders a link to the external app', () => {
      expect(wrapper.find(ReviewAppLink).attributes('link')).toBe(
        propsData.environment.external_url,
      );
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('with environments grouped into a folder', () => {
    beforeEach(() => {
      propsData.environment.size = 5;
      propsData.environment.within_folder = true;
      propsData.environment.name = 'review/testing';

      wrapper = shallowMount(Component, {
        sync: false,
        attachToDocument: true,
        propsData,
        localVue,
      });
    });

    it('shows a badge with the number of other environments in the folder', () => {
      const expected = propsData.environment.size.toString();
      expect(wrapper.find(GlBadge).text()).toBe(expected);
    });

    it('shows an icon stating the environment is one of many in a folder', () => {
      expect(wrapper.find(Icon).attributes('name')).toBe('information');
      expect(wrapper.find(Icon).attributes('title')).toMatch(/last updated environment/);
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('has errors', () => {
    beforeEach(() => {
      propsData.hasErrors = true;

      wrapper = shallowMount(Component, {
        sync: false,
        attachToDocument: true,
        propsData,
        localVue,
      });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('has a failed pipeline', () => {
    beforeEach(() => {
      propsData.hasPipelineFailed = true;

      wrapper = shallowMount(Component, {
        sync: false,
        attachToDocument: true,
        propsData,
        localVue,
      });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
