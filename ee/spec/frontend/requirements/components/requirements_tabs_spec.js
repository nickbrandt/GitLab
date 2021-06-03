import { GlTab, GlBadge, GlButton, GlTabs } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import RequirementsTabs from 'ee/requirements/components/requirements_tabs.vue';
import { FilterState } from 'ee/requirements/constants';

import { mockRequirementsCount } from '../mock_data';

const createComponent = ({
  filterBy = FilterState.opened,
  requirementsCount = mockRequirementsCount,
  showCreateForm = false,
  canCreateRequirement = true,
} = {}) =>
  shallowMount(RequirementsTabs, {
    propsData: {
      filterBy,
      requirementsCount,
      showCreateForm,
      canCreateRequirement,
    },
    stubs: {
      GlTabs,
      GlTab,
    },
  });

describe('RequirementsTabs', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders "Open" tab', () => {
      const tabEl = wrapper.findAll(GlTab).at(0);

      expect(tabEl.text()).toContain('Open');
      expect(tabEl.find(GlBadge).text()).toBe(`${mockRequirementsCount.OPENED}`);
    });

    it('renders "Closed" tab', () => {
      const tabEl = wrapper.findAll(GlTab).at(1);

      expect(tabEl.text()).toContain('Closed');
      expect(tabEl.find(GlBadge).text()).toBe(`${mockRequirementsCount.CLOSED}`);
    });

    it('renders "All" tab', () => {
      const tabEl = wrapper.findAll(GlTab).at(2);

      expect(tabEl.text()).toContain('All');
      expect(tabEl.find(GlBadge).text()).toBe(`${mockRequirementsCount.ALL}`);
    });

    it('renders class `active` on currently selected tab', () => {
      const tabEl = wrapper.findAll(GlTab).at(0);

      expect(tabEl.attributes('active')).toBeDefined();
    });

    it('renders "New requirement" button when current tab is "Open" tab', () => {
      wrapper.setProps({
        filterBy: FilterState.opened,
      });

      return wrapper.vm.$nextTick(() => {
        const buttonEl = wrapper.findAll(GlButton).at(2);

        expect(buttonEl.exists()).toBe(true);
        expect(buttonEl.text()).toBe('New requirement');
      });
    });

    it('does not render "New requirement" button when current tab is not "Open" tab', () => {
      wrapper.setProps({
        filterBy: FilterState.closed,
      });

      return wrapper.vm.$nextTick(() => {
        const buttonEl = wrapper.find(GlButton);

        expect(buttonEl.exists()).toBe(false);
      });
    });

    it('does not render "New requirement" button when `canCreateRequirement` prop is false', () => {
      wrapper.setProps({
        filterBy: FilterState.opened,
        canCreateRequirement: false,
      });

      return wrapper.vm.$nextTick(() => {
        const buttonEl = wrapper.find(GlButton);

        expect(buttonEl.exists()).toBe(false);
      });
    });

    it('disables "New requirement" button when `showCreateForm` is true', () => {
      wrapper.setProps({
        showCreateForm: true,
      });

      return wrapper.vm.$nextTick(() => {
        const buttonEl = wrapper.findAll(GlButton);

        expect(buttonEl.at(0).props('disabled')).toBe(true);
        expect(buttonEl.at(1).props('disabled')).toBe(true);
        expect(buttonEl.at(2).props('disabled')).toBe(true);
      });
    });
  });
});
