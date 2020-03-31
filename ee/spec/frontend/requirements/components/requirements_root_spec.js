import { shallowMount } from '@vue/test-utils';

import { GlPagination } from '@gitlab/ui';
import RequirementsRoot from 'ee/requirements/components/requirements_root.vue';
import RequirementsLoading from 'ee/requirements/components/requirements_loading.vue';
import RequirementsEmptyState from 'ee/requirements/components/requirements_empty_state.vue';
import RequirementItem from 'ee/requirements/components/requirement_item.vue';

import {
  FilterState,
  mockRequirementsOpen,
  mockRequirementsCount,
  mockPageInfo,
} from '../mock_data';

jest.mock('ee/requirements/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
}));

const createComponent = ({
  projectPath = 'gitlab-org/gitlab-shell',
  filterBy = FilterState.opened,
  requirementsCount = mockRequirementsCount,
  showCreateRequirement = false,
  emptyStatePath = '/assets/illustrations/empty-state/requirements.svg',
  loading = false,
} = {}) =>
  shallowMount(RequirementsRoot, {
    propsData: {
      projectPath,
      filterBy,
      requirementsCount,
      showCreateRequirement,
      emptyStatePath,
    },
    mocks: {
      $apollo: {
        queries: {
          requirements: {
            loading,
            list: [],
            pageInfo: {},
            count: {},
          },
        },
      },
    },
  });

describe('RequirementsRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('totalRequirements', () => {
      it('returns number representing total requirements for current tab', () => {
        expect(wrapper.vm.totalRequirements).toBe(mockRequirementsCount.OPENED);
      });
    });

    describe('showPaginationControls', () => {
      it('returns `true` when totalRequirements is more than default page size', () => {
        wrapper.setData({
          requirements: {
            list: mockRequirementsOpen,
            count: mockRequirementsCount,
            pageInfo: mockPageInfo,
          },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.showPaginationControls).toBe(true);
        });
      });

      it('returns `false` when totalRequirements is less than default page size', () => {
        wrapper.setData({
          requirements: {
            list: [mockRequirementsOpen[0]],
            count: {
              ...mockRequirementsCount,
              OPENED: 1,
            },
            pageInfo: mockPageInfo,
          },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.showPaginationControls).toBe(false);
        });
      });
    });

    describe('prevPage', () => {
      it('returns number representing previous page based on currentPage value', () => {
        wrapper.setData({
          currentPage: 3,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.prevPage).toBe(2);
        });
      });
    });

    describe('nextPage', () => {
      it('returns number representing next page based on currentPage value', () => {
        expect(wrapper.vm.nextPage).toBe(2);
      });

      it('returns `null` when currentPage is already last page', () => {
        wrapper.setData({
          currentPage: 2,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.nextPage).toBeNull();
        });
      });
    });
  });

  describe('methods', () => {
    describe('updateUrl', () => {
      it('updates window URL with query params `page` and `prev`', () => {
        wrapper.vm.updateUrl({
          page: 2,
          prev: mockPageInfo.startCursor,
        });

        expect(global.window.location.href).toContain(`?page=2&prev=${mockPageInfo.startCursor}`);
      });

      it('updates window URL with query params `page` and `next`', () => {
        wrapper.vm.updateUrl({
          page: 1,
          next: mockPageInfo.endCursor,
        });

        expect(global.window.location.href).toContain(`?page=1&next=${mockPageInfo.endCursor}`);
      });
    });

    describe('handlePageChange', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'updateUrl').mockImplementation(jest.fn());

        wrapper.setData({
          requirements: {
            list: mockRequirementsOpen,
            count: mockRequirementsCount,
            pageInfo: mockPageInfo,
          },
        });

        return wrapper.vm.$nextTick();
      });

      it('calls `updateUrl` with `page` and `next` params when value of page is `2`', () => {
        wrapper.vm.handlePageChange(2);

        expect(wrapper.vm.updateUrl).toHaveBeenCalledWith({
          page: 2,
          prev: '',
          next: mockPageInfo.endCursor,
        });
      });

      it('calls `updateUrl` with `page` and `next` params when value of page is `1`', () => {
        wrapper.setData({
          currentPage: 2,
        });

        return wrapper.vm.$nextTick(() => {
          wrapper.vm.handlePageChange(1);

          expect(wrapper.vm.updateUrl).toHaveBeenCalledWith({
            page: 1,
            prev: mockPageInfo.startCursor,
            next: '',
          });
        });
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `requirements-list-container`', () => {
      expect(wrapper.classes()).toContain('requirements-list-container');
    });

    it('renders empty state when query results are empty', () => {
      expect(wrapper.find(RequirementsEmptyState).exists()).toBe(true);
    });

    it('renders requirements-loading component when query results are still being loaded', () => {
      const wrapperLoading = createComponent({ loading: true });

      expect(wrapperLoading.find(RequirementsLoading).isVisible()).toBe(true);

      wrapperLoading.destroy();
    });

    it('renders requirement items for all the requirements', () => {
      wrapper.setData({
        requirements: {
          list: mockRequirementsOpen,
          count: mockRequirementsCount,
          pageInfo: mockPageInfo,
        },
      });

      return wrapper.vm.$nextTick(() => {
        const itemsContainer = wrapper.find('ul.requirements-list');

        expect(itemsContainer.exists()).toBe(true);
        expect(itemsContainer.findAll(RequirementItem)).toHaveLength(mockRequirementsOpen.length);
      });
    });

    it('renders pagination controls', () => {
      wrapper.setData({
        requirements: {
          list: mockRequirementsOpen,
          count: mockRequirementsCount,
          pageInfo: mockPageInfo,
        },
      });

      return wrapper.vm.$nextTick(() => {
        const pagination = wrapper.find(GlPagination);

        expect(pagination.exists()).toBe(true);
        expect(pagination.props('value')).toBe(1);
        expect(pagination.props('perPage')).toBe(2); // We're mocking this page size
        expect(pagination.props('align')).toBe('center');
      });
    });
  });
});
