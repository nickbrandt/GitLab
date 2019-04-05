import { shallowMount } from '@vue/test-utils';
import { SkeletonHeaderCell } from 'ee/licenses/components/cells';

describe('SkeletonHeaderCell', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(SkeletonHeaderCell);
  }

  afterEach(() => {
    if (wrapper) wrapper.destroy();
  });

  it('renders a skeleton cell with a single title loading bar', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
