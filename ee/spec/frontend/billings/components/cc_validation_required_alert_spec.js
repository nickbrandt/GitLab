import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CreditCardValidationRequiredAlert from 'ee/billings/components/cc_validation_required_alert.vue';
import { TEST_HOST } from 'helpers/test_constants';

describe('CreditCardValidationRequiredAlert', () => {
  let wrapper;

  const createComponent = () => {
    return shallowMount(CreditCardValidationRequiredAlert, {
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    window.gon = {
      subscriptions_url: TEST_HOST,
      payment_form_url: TEST_HOST,
    };

    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders title', () => {
    expect(wrapper.findComponent(GlAlert).attributes('title')).toBe('User Verification Required');
  });

  it('renders description', () => {
    expect(wrapper.findComponent(GlAlert).text()).toContain(
      'As a user on a free or trial namespace',
    );
  });
});
