import { shallowMount } from '@vue/test-utils';

import { GlLoadingIcon } from '@gitlab/ui';
import RequirementsRoot from 'ee/requirements/components/requirements_root.vue';
import RequirementsEmptyState from 'ee/requirements/components/requirements_empty_state.vue';
import RequirementItem from 'ee/requirements/components/requirement_item.vue';
import { FilterState } from 'ee/requirements/constants';

import { mockRequirements } from '../mock_data';

const createComponent = ({
  projectPath = 'gitlab-org/gitlab-shell',
  filterBy = FilterState.opened,
  showCreateRequirement = false,
  emptyStatePath = '/assets/illustrations/empty-state/requirements.svg',
  loading = false,
} = {}) =>
  shallowMount(RequirementsRoot, {
    propsData: {
      projectPath,
      filterBy,
      showCreateRequirement,
      emptyStatePath,
    },
    mocks: {
      $apollo: {
        queries: {
          requirements: {
            loading,
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

  describe('template', () => {
    it('renders component container element with class `requirements-list-container`', () => {
      expect(wrapper.classes()).toContain('requirements-list-container');
    });

    it('renders empty state query results are empty', () => {
      expect(wrapper.find(RequirementsEmptyState).exists()).toBe(true);
    });

    it('renders loading icon when query results are still being loaded', () => {
      const wrapperLoading = createComponent({ loading: true });

      expect(wrapperLoading.find(GlLoadingIcon).exists()).toBe(true);

      wrapperLoading.destroy();
    });

    it('renders requirement items for all the requirements', () => {
      wrapper.setData({
        requirements: mockRequirements,
      });

      return wrapper.vm.$nextTick(() => {
        const itemsContainer = wrapper.find('ul.requirements-list');

        expect(itemsContainer.exists()).toBe(true);
        expect(itemsContainer.findAll(RequirementItem).length).toBe(mockRequirements.length);
      });
    });
  });
});
