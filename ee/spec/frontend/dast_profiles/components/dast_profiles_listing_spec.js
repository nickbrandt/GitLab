import { shallowMount } from '@vue/test-utils';
import { within } from '@testing-library/dom';
import DastProfilesListing from 'ee/dast_profiles/components/dast_profiles_listing.vue';

describe('EE - DastProfilesListing', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(DastProfilesListing);
  };

  const withinComponent = () => within(wrapper.element);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('empty state', () => {
    it('shows a message to indicate that no profiles exist', () => {
      const emptyStateMessage = withinComponent().getByText(/no profiles created yet/i);

      expect(emptyStateMessage).not.toBe(null);
    });
  });
});
