import { shallowMount } from '@vue/test-utils';

import { GlPagination } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import createFlash from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';

import RequirementsRoot from 'ee/requirements/components/requirements_root.vue';
import RequirementsLoading from 'ee/requirements/components/requirements_loading.vue';
import RequirementsEmptyState from 'ee/requirements/components/requirements_empty_state.vue';
import RequirementItem from 'ee/requirements/components/requirement_item.vue';
import RequirementForm from 'ee/requirements/components/requirement_form.vue';

import createRequirement from 'ee/requirements/queries/createRequirement.mutation.graphql';
import updateRequirement from 'ee/requirements/queries/updateRequirement.mutation.graphql';

import {
  FilterState,
  mockRequirementsOpen,
  mockRequirementsCount,
  mockPageInfo,
} from '../mock_data';

jest.mock('ee/requirements/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
  FilterState: {
    opened: 'OPENED',
    archived: 'ARCHIVED',
    all: 'ALL',
  },
}));

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const createComponent = ({
  projectPath = 'gitlab-org/gitlab-shell',
  filterBy = FilterState.opened,
  requirementsCount = mockRequirementsCount,
  showCreateRequirement = false,
  emptyStatePath = '/assets/illustrations/empty-state/requirements.svg',
  loading = false,
  requirementsWebUrl = '/gitlab-org/gitlab-shell/-/requirements',
} = {}) =>
  shallowMount(RequirementsRoot, {
    propsData: {
      projectPath,
      filterBy,
      requirementsCount,
      showCreateRequirement,
      emptyStatePath,
      requirementsWebUrl,
    },
    mocks: {
      $apollo: {
        queries: {
          requirements: {
            loading,
            list: [],
            pageInfo: {},
            count: {},
            refetch: jest.fn(),
          },
        },
        mutate: jest.fn(),
      },
    },
  });

describe('RequirementsRoot', () => {
  let wrapper;

  beforeEach(() => {
    setFixtures(`
      <div class="js-nav-requirements-count"></div>
      <div class="js-nav-requirements-count-fly-out"></div>
      <div class="js-requirements-state-filters">
        <span class="js-opened-count"></span>
        <span class="js-archived-count"></span>
        <span class="js-all-count"></span>
      </div>
      <button class="js-new-requirement">New requirement</button>
    `);
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
    const mockUpdateMutationResult = {
      data: {
        updateRequirement: {
          errors: [],
          requirement: {
            iid: '1',
            title: 'foo',
          },
        },
      },
    };

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

    describe('updateRequirement', () => {
      it('calls `$apollo.mutate` with `updateRequirement` mutation and variables containing `projectPath` & `iid`', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.updateRequirement({
          iid: '1',
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateRequirement,
            variables: {
              updateRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                iid: '1',
              },
            },
          }),
        );
      });

      it('calls `$apollo.mutate` with variables containing `title` when it is included in object param', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.updateRequirement({
          iid: '1',
          title: 'foo',
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateRequirement,
            variables: {
              updateRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                iid: '1',
                title: 'foo',
              },
            },
          }),
        );
      });

      it('calls `$apollo.mutate` with variables containing `state` when it is included in object param', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.updateRequirement({
          iid: '1',
          state: FilterState.opened,
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateRequirement,
            variables: {
              updateRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                iid: '1',
                state: FilterState.opened,
              },
            },
          }),
        );
      });

      it('calls `createFlash` with provided `errorFlashMessage` param and `Sentry.captureException` when request fails', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(new Error());
        jest.spyOn(Sentry, 'captureException').mockImplementation();

        return wrapper.vm
          .updateRequirement({
            iid: '1',
            errorFlashMessage: 'Something went wrong',
          })
          .then(() => {
            expect(createFlash).toHaveBeenCalledWith('Something went wrong');
            expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Object));
          });
      });
    });

    describe('enableOrDisableNewRequirement', () => {
      it('disables new requirement button when called with param `{ disable: true }`', () => {
        wrapper.vm.enableOrDisableNewRequirement({
          disable: true,
        });

        return wrapper.vm.$nextTick(() => {
          const newReqButton = document.querySelector('.js-new-requirement');

          expect(newReqButton.getAttribute('disabled')).toBe('disabled');
          expect(newReqButton.classList.contains('disabled')).toBe(true);
        });
      });

      it('enables new requirement button when called with param `{ disable: false }`', () => {
        wrapper.vm.enableOrDisableNewRequirement({
          disable: false,
        });

        return wrapper.vm.$nextTick(() => {
          const newReqButton = document.querySelector('.js-new-requirement');

          expect(newReqButton.getAttribute('disabled')).toBeNull();
          expect(newReqButton.classList.contains('disabled')).toBe(false);
        });
      });
    });

    describe('handleNewRequirementClick', () => {
      it('sets `showCreateForm` prop to `true`', () => {
        wrapper.vm.handleNewRequirementClick();

        expect(wrapper.vm.showCreateForm).toBe(true);
      });
    });

    describe('handleEditRequirementClick', () => {
      it('sets `showUpdateFormForRequirement` prop to value of passed param', () => {
        wrapper.vm.handleEditRequirementClick('10');

        expect(wrapper.vm.showUpdateFormForRequirement).toBe('10');
      });
    });

    describe('handleNewRequirementSave', () => {
      const mockMutationResult = {
        data: {
          createRequirement: {
            errors: [],
          },
        },
      };

      it('sets `createRequirementRequestActive` prop to `true`', () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockReturnValue(Promise.resolve(mockMutationResult));

        wrapper.vm.handleNewRequirementSave('foo');

        expect(wrapper.vm.createRequirementRequestActive).toBe(true);
      });

      it('calls `$apollo.mutate` with createRequirement mutation and `projectPath` & `title` as variables', () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockReturnValue(Promise.resolve(mockMutationResult));

        wrapper.vm.handleNewRequirementSave('foo');

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: createRequirement,
            variables: {
              createRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                title: 'foo',
              },
            },
          }),
        );
      });

      it('calls `visitUrl` when project has no requirements and request is successful', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockMutationResult);

        wrapper.setProps({
          requirementsCount: {
            OPENED: 0,
            ARCHIVED: 0,
            ALL: 0,
          },
        });

        return wrapper.vm.handleNewRequirementSave('foo').then(() => {
          expect(visitUrl).toHaveBeenCalledWith('/gitlab-org/gitlab-shell/-/requirements');
        });
      });

      it('sets `showCreateForm` and `createRequirementRequestActive` props to `false` and calls `$apollo.queries.requirements.refetch()` when request is successful', () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockReturnValue(Promise.resolve(mockMutationResult));
        jest
          .spyOn(wrapper.vm.$apollo.queries.requirements, 'refetch')
          .mockImplementation(jest.fn());

        return wrapper.vm.handleNewRequirementSave('foo').then(() => {
          expect(wrapper.vm.showCreateForm).toBe(false);
          expect(wrapper.vm.$apollo.queries.requirements.refetch).toHaveBeenCalled();
          expect(wrapper.vm.createRequirementRequestActive).toBe(false);
        });
      });

      it('sets `createRequirementRequestActive` prop to `false` and calls `createFlash` when `$apollo.mutate` request fails', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockReturnValue(Promise.reject(new Error()));

        return wrapper.vm.handleNewRequirementSave('foo').then(() => {
          expect(createFlash).toHaveBeenCalledWith(
            'Something went wrong while creating a requirement.',
          );
          expect(wrapper.vm.createRequirementRequestActive).toBe(false);
        });
      });
    });

    describe('handleUpdateRequirementSave', () => {
      it('sets `createRequirementRequestActive` prop to `true`', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.handleUpdateRequirementSave({
          title: 'foo',
        });

        expect(wrapper.vm.createRequirementRequestActive).toBe(true);
      });

      it('calls `updateRequirement` with object containing `iid`, `title` & `errorFlashMessage` props', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.handleUpdateRequirementSave({
          iid: '1',
          title: 'foo',
        });

        expect(wrapper.vm.updateRequirement).toHaveBeenCalledWith(
          expect.objectContaining({
            iid: '1',
            title: 'foo',
            errorFlashMessage: 'Something went wrong while updating a requirement.',
          }),
        );
      });

      it('sets `showUpdateFormForRequirement` to `0` and `createRequirementRequestActive` prop to `false` when request is successful', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        return wrapper.vm
          .handleUpdateRequirementSave({
            iid: '1',
            title: 'foo',
          })
          .then(() => {
            expect(wrapper.vm.showUpdateFormForRequirement).toBe(0);
            expect(wrapper.vm.createRequirementRequestActive).toBe(false);
          });
      });

      it('sets `createRequirementRequestActive` prop to `false` when request fails', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockRejectedValue(new Error());

        return wrapper.vm
          .handleUpdateRequirementSave({
            title: 'foo',
          })
          .catch(() => {
            expect(wrapper.vm.createRequirementRequestActive).toBe(false);
          });
      });
    });

    describe('handleNewRequirementCancel', () => {
      it('sets `showCreateForm` prop to `false`', () => {
        wrapper.setData({
          showCreateForm: true,
        });

        wrapper.vm.handleNewRequirementCancel();

        expect(wrapper.vm.showCreateForm).toBe(false);
      });
    });

    describe('handleRequirementStateChange', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);
      });

      it('sets `stateChangeRequestActiveFor` value to `iid` provided within object param', () => {
        wrapper.vm.handleRequirementStateChange({
          iid: '1',
        });

        expect(wrapper.vm.stateChangeRequestActiveFor).toBe('1');
      });

      it('calls `updateRequirement` with object containing params and errorFlashMessage when `params.state` is "OPENED"', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.updateRequirement).toHaveBeenCalledWith(
              expect.objectContaining({
                iid: '1',
                state: FilterState.opened,
                errorFlashMessage: 'Something went wrong while reopening a requirement.',
              }),
            );
          });
      });

      it('calls `updateRequirement` with object containing params and errorFlashMessage when `params.state` is "ARCHIVED"', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.archived,
          })
          .then(() => {
            expect(wrapper.vm.updateRequirement).toHaveBeenCalledWith(
              expect.objectContaining({
                iid: '1',
                state: FilterState.archived,
                errorFlashMessage: 'Something went wrong while archiving a requirement.',
              }),
            );
          });
      });

      it('sets `stateChangeRequestActiveFor` to 0', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.stateChangeRequestActiveFor).toBe(0);
          });
      });

      it('increments `openedCount` by 1 and decrements `archivedCount` by 1 when `params.state` is "OPENED"', () => {
        wrapper.setData({
          openedCount: 1,
          archivedCount: 1,
        });

        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.openedCount).toBe(2);
            expect(wrapper.vm.archivedCount).toBe(0);
          });
      });

      it('decrements `openedCount` by 1 and increments `archivedCount` by 1 when `params.state` is "ARCHIVED"', () => {
        wrapper.setData({
          openedCount: 1,
          archivedCount: 1,
        });

        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.archived,
          })
          .then(() => {
            expect(wrapper.vm.openedCount).toBe(0);
            expect(wrapper.vm.archivedCount).toBe(2);
          });
      });
    });

    describe('handleUpdateRequirementCancel', () => {
      it('sets `showUpdateFormForRequirement` prop to `0`', () => {
        wrapper.vm.handleUpdateRequirementCancel();

        expect(wrapper.vm.showUpdateFormForRequirement).toBe(0);
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

    it('renders requirement-form component when `showCreateForm` prop is `true`', () => {
      wrapper.setData({
        showCreateForm: true,
      });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(RequirementForm).exists()).toBe(true);
      });
    });

    it('does not render requirement-empty-state component when `showCreateForm` prop is `true`', () => {
      wrapper.setData({
        showCreateForm: true,
      });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(RequirementsEmptyState).exists()).toBe(false);
      });
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
