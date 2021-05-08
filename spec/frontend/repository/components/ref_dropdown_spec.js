import { GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';

import axios from '~/lib/utils/axios_utils';
import RefDropdown from '~/repository/components/ref_dropdown.vue';

const defaultProps = {
  refsProjectPath: 'some/project/path',
  currentRef: 'master',
};

describe('RefDropdown component', () => {
  let wrapper;
  let axiosMock;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RefDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlDropdown,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    axiosMock.restore();
  });

  const findGlDropdown = () => wrapper.find(GlDropdown);

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  it('renders component', () => {
    createComponent();
    expect(wrapper.props()).toMatchObject(defaultProps);
  });

  describe('GlDropdown component', () => {
    it('renders default text', () => {
      createComponent({
        currentRef: null,
      });
      expect(findGlDropdown().props('text')).toBe('Select branch/tag');
    });

    it('display currentRef text', () => {
      createComponent();
      expect(findGlDropdown().props('text')).toBe(defaultProps.currentRef);
    });
  });
});
