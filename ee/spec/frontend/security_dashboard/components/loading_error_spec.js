import { shallowMount } from '@vue/test-utils';

import { GlEmptyState } from '@gitlab/ui';

import LoadingError from 'ee/security_dashboard/components/loading_error.vue';

describe('LoadingError component', () => {
  let wrapper;

  const createWrapper = errorCode => {
    wrapper = shallowMount(LoadingError, {
      propsData: {
        errorCode,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each([401, 403])('with error code %s', errorCode => {
    beforeEach(() => {
      createWrapper(errorCode);
    });

    it('renders an empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });

    it('empty state has correct props', () => {
      expect(wrapper.find(GlEmptyState).props()).toMatchSnapshot();
    });
  });
});
