import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import Component from 'ee/analytics/code_analytics/components/app.vue';

const emptyStateSvgPath = 'path/to/empty/state';

const localVue = createLocalVue();
localVue.use(Vuex);

let wrapper;

const createComponent = () =>
  shallowMount(Component, {
    localVue,
    sync: false,
    propsData: {
      emptyStateSvgPath,
    },
  });

describe('Code Analytics component', () => {
  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('displays the components as required', () => {
    it('displays an empty state', () => {
      const emptyState = wrapper.find(GlEmptyState);

      expect(emptyState.exists()).toBe(true);
      expect(emptyState.props('title')).toBe(
        'Identify the most frequently changed files in your repository',
      );
      expect(emptyState.props('description')).toBe(
        'Identify areas of the codebase associated with a lot of churn, which can indicate potential code hotspots.',
      );
      expect(emptyState.props('svgPath')).toBe(emptyStateSvgPath);
    });
  });
});
