import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ListEmptyState from 'ee/groups/settings/compliance_frameworks/components/list_empty_state.vue';

describe('ListEmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.find(GlEmptyState);
  const createComponent = (props = {}) => {
    wrapper = shallowMount(ListEmptyState, {
      propsData: {
        imagePath: 'dir/image.svg',
        addFrameworkPath: 'group/framework/new',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('has the correct props', () => {
    createComponent();

    expect(findEmptyState().props()).toMatchObject({
      title: 'There are no compliance frameworks set up yet',
      description: 'Once a compliance framework is added it will appear here.',
      svgPath: 'dir/image.svg',
      primaryButtonLink: 'group/framework/new',
      primaryButtonText: 'Add framework',
      svgHeight: 110,
      compact: true,
    });
  });
});
