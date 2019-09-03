import { shallowMount } from '@vue/test-utils';
import List from 'ee/design_management/components/list/index.vue';

const createMockDesign = id => ({
  id,
  filename: 'test',
  image: 'test',
  commentsCount: 2,
  updatedAt: '01-01-2019',
});

describe('Design management list component', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(List, {
      sync: false,
      propsData: {
        designs: [createMockDesign(1), createMockDesign(2)],
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders list', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
