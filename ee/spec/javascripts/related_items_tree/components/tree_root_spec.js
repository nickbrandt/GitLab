import { shallowMount, createLocalVue } from '@vue/test-utils';

import TreeRoot from 'ee/related_items_tree/components/tree_root.vue';

import { ChildType } from 'ee/related_items_tree/constants';

import { mockParentItem, mockEpic1 } from '../mock_data';

const mockItem = Object.assign({}, mockEpic1, {
  type: ChildType.Epic,
  pathIdSeparator: '&',
});

const createComponent = (parentItem = mockParentItem, children = [mockItem]) => {
  const localVue = createLocalVue();

  return shallowMount(TreeRoot, {
    localVue,
    stubs: {
      'tree-item': true,
    },
    propsData: {
      parentItem,
      children,
    },
  });
};

describe('RelatedItemsTree', () => {
  describe('TreeRoot', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('template', () => {
      it('renders tree item component', () => {
        expect(wrapper.html()).toContain('tree-item-stub');
      });
    });
  });
});
