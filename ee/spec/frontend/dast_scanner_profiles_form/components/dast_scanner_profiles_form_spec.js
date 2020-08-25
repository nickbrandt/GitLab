import merge from 'lodash/merge';
import { shallowMount } from '@vue/test-utils';
import DastScannerProfileForm from 'ee/dast_scanner_profiles/components/dast_scanner_profile_form.vue';

const defaultProps = {};

describe('DastScannerProfileForm', () => {
  let wrapper;

  const wrapperFactory = (mountFn = shallowMount) => options => {
    wrapper = mountFn(
      DastScannerProfileForm,
      merge(
        {},
        {
          propsData: defaultProps,
          mocks: {
            $apollo: {
              mutate: jest.fn(),
            },
          },
        },
        options,
      ),
    );
  };
  const createWrapper = wrapperFactory();

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the title', () => {
    createWrapper();
    expect(wrapper.html()).toContain('<h1>New Scanner Profile</h1>');
  });
});
