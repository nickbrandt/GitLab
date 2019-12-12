import { shallowMount, createLocalVue } from '@vue/test-utils';
import { Accordion } from 'ee/vue_shared/components/accordion';

import { uniqueId } from 'underscore';

jest.mock('underscore');

const localVue = createLocalVue();

describe('Accordion component', () => {
  let wrapper;
  const factory = ({ defaultSlot = '' } = {}) => {
    wrapper = shallowMount(Accordion, {
      localVue,
      sync: false,
      scopedSlots: {
        default: defaultSlot,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    jest.clearAllMocks();
  });

  it('contains a default slot', () => {
    const defaultSlot = `<span class="content"></span>`;

    factory({ defaultSlot });

    expect(wrapper.find('.content').exists()).toBe(true);
  });

  it('passes a unique "accordionId" to the default slot', () => {
    const mockUniqueIdValue = 'foo';
    uniqueId.mockReturnValueOnce(mockUniqueIdValue);

    const defaultSlot = '<span>{{ props.accordionId }}</span>';

    factory({ defaultSlot });

    expect(wrapper.text()).toContain(mockUniqueIdValue);
  });
});
