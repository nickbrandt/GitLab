import { shallowMount } from '@vue/test-utils';

import { GlSkeletonLoading } from '@gitlab/ui';
import RequirementsLoading from 'ee/requirements/components/requirements_loading.vue';

import { FilterState, mockRequirementsCount } from '../mock_data';

jest.mock('ee/requirements/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
}));

const createComponent = ({
  filterBy = FilterState.opened,
  currentTabCount = mockRequirementsCount.OPENED,
  currentPage = 1,
} = {}) =>
  shallowMount(RequirementsLoading, {
    propsData: {
      filterBy,
      currentTabCount,
      currentPage,
    },
  });

describe('RequirementsLoading', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('lastPage', () => {
      it('returns number representing last page of the list', () => {
        expect(wrapper.vm.lastPage).toBe(2);
      });
    });

    describe('loaderCount', () => {
      it('returns value of DEFAULT_PAGE_SIZE when current page is not the last page total requirements are more than DEFAULT_PAGE_SIZE', () => {
        expect(wrapper.vm.loaderCount).toBe(2);
      });

      it('returns value of remainder requirements for last page when current page is the last page total requirements are more than DEFAULT_PAGE_SIZE', () => {
        wrapper.setProps({
          currentPage: 2,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.loaderCount).toBe(1);
        });
      });

      it('returns value DEFAULT_PAGE_SIZE when current page is the last page total requirements are less than DEFAULT_PAGE_SIZE', () => {
        wrapper.setProps({
          currentPage: 1,
          currentTabCount: 1,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.loaderCount).toBe(1);
        });
      });
    });
  });

  describe('template', () => {
    it('renders gl-skeleton-loading component based on loaderCount', () => {
      const loaders = wrapper.find('.requirements-list-loading').findAll(GlSkeletonLoading);

      expect(loaders.length).toBe(2);
      expect(loaders.at(0).props('lines')).toBe(2);
    });
  });
});
