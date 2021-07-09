import { shallowMount } from '@vue/test-utils';

import DrawerSectionHeader from 'ee/compliance_dashboard/components/shared/drawer_section_header.vue';

describe('DrawerSectionHeader component', () => {
  let wrapper;
  const headerText = 'Section header';

  const createComponent = () => {
    return shallowMount(DrawerSectionHeader, {
      slots: {
        default: headerText,
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the header text', () => {
    expect(wrapper.text()).toBe(headerText);
  });
});
