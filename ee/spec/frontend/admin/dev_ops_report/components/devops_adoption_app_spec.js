import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import DevopsAdoptionApp from 'ee/admin/dev_ops_report/components/devops_adoption_app.vue';
import DevopsAdoptionEmptyState from 'ee/admin/dev_ops_report/components/devops_adoption_empty_state.vue';
import { DEVOPS_ADOPTION_STRINGS } from 'ee/admin/dev_ops_report//constants';
import * as Sentry from '~/sentry/wrapper';
import { groupNodes, groupPageInfo } from '../mock_data';

const localVue = createLocalVue();

describe('DevopsAdoptionApp', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const {
      loading = true,
      groups = [],
      pageInfo = groupPageInfo,
      fetchMore = jest.fn(),
    } = options;
    return shallowMount(DevopsAdoptionApp, {
      localVue,
      data() {
        return {
          groups: {
            nodes: groups,
            pageInfo,
          },
        };
      },
      mocks: {
        $apollo: {
          queries: {
            groups: {
              loading,
              fetchMore,
            },
          },
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when loading', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('does not display the empty state', () => {
      expect(wrapper.find(DevopsAdoptionEmptyState).exists()).toBe(false);
    });

    it('displays the loader', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('when no data is present', () => {
    beforeEach(() => {
      wrapper = createComponent({ loading: false });
    });

    it('displays the empty state', () => {
      expect(wrapper.find(DevopsAdoptionEmptyState).exists()).toBe(true);
    });

    it('does not display the loader', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    });
  });

  describe('when data is present', () => {
    let fetchMore;

    beforeEach(() => {
      const pageInfo = { ...groupPageInfo, nextPage: 1 };
      fetchMore = jest.fn().mockImplementation(() => new Promise(resolve => resolve()));
      wrapper = createComponent({ loading: false, groups: groupNodes, pageInfo, fetchMore });
      wrapper.vm.$options.apollo.groups.result.call(wrapper.vm);
    });

    it('does not display the empty state', () => {
      expect(wrapper.find(DevopsAdoptionEmptyState).exists()).toBe(false);
    });

    it('does not display the loader', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    });

    it('should fetch more data', () => {
      expect(fetchMore).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: { nextPage: 1 },
        }),
      );
    });
  });

  describe('when error is thrown', () => {
    let fetchMore;
    const error = 'Error: foo!';

    beforeEach(() => {
      const pageInfo = { ...groupPageInfo, nextPage: 1 };
      fetchMore = jest
        .fn()
        .mockImplementation(() => new Promise((resolve, reject) => reject(error)));
      jest.spyOn(Sentry, 'captureException');
      wrapper = createComponent({ loading: false, groups: groupNodes, pageInfo, fetchMore });
      wrapper.vm.$options.apollo.groups.result.call(wrapper.vm);
    });

    it('does not display the empty state', () => {
      expect(wrapper.find(DevopsAdoptionEmptyState).exists()).toBe(false);
    });

    it('does not display the loader', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    });

    it('displays the error message and calls Sentry', () => {
      const altert = wrapper.find(GlAlert);
      expect(altert.exists()).toBe(true);
      expect(altert.text()).toBe(DEVOPS_ADOPTION_STRINGS.app.groupsError);
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });
});
