import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import Cell from 'ee/licenses/components/cells/cell.vue';
import { HeaderCell } from 'ee/licenses/components/cells';

describe('HeaderCell', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(HeaderCell, {
      propsData: {
        title: 'title',
        icon: 'retry',
      },
      stubs: {
        Cell,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    if (wrapper) wrapper.destroy();
  });

  it('renders a cell with the correct "inflexible" value', () => {
    expect(wrapper.find(Cell).props('isFlexible')).toBe(false);
  });

  it('renders an icon and title', () => {
    expect(wrapper.find(GlIcon).props('name')).toBe('retry');
    expect(wrapper.find(Cell).text()).toContain('title');
  });
});
