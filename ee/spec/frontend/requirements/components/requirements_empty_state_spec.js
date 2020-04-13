import { shallowMount } from '@vue/test-utils';

import { GlEmptyState } from '@gitlab/ui';
import RequirementsEmptyState from 'ee/requirements/components/requirements_empty_state.vue';
import { FilterState } from 'ee/requirements/constants';

const createComponent = (
  filterBy = FilterState.opened,
  emptyStatePath = '/assets/illustrations/empty-state/requirements.svg',
) =>
  shallowMount(RequirementsEmptyState, {
    propsData: {
      filterBy,
      emptyStatePath,
    },
  });

describe('RequirementsEmptyState', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('emptyStateTitle', () => {
      it('returns string "There are no open requirements" when value of `filterBy` prop is "OPENED"', () => {
        expect(wrapper.vm.emptyStateTitle).toBe('There are no open requirements');
      });

      it('returns string "There are no archived requirements" when value of `filterBy` prop is "ARCHIVED"', () => {
        wrapper.setProps({
          filterBy: FilterState.archived,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.emptyStateTitle).toBe('There are no archived requirements');
        });
      });
    });
  });

  describe('template', () => {
    it('renders empty state element', () => {
      const emptyStateEl = wrapper.find(GlEmptyState);

      expect(emptyStateEl.exists()).toBe(true);
      expect(emptyStateEl.props('title')).toBe('There are no open requirements');
      expect(emptyStateEl.attributes('svgpath')).toBe(
        '/assets/illustrations/empty-state/requirements.svg',
      );
    });
  });
});
