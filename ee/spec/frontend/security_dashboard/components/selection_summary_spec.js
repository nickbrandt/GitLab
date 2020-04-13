import { mount } from '@vue/test-utils';
import SelectionSummary from 'ee/security_dashboard/components/selection_summary.vue';
import { GlFormSelect, GlNewButton } from '@gitlab/ui';
import createFlash from '~/flash';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/flash');
jest.mock('~/vue_shared/plugins/global_toast');

describe('Selection Summary component', () => {
  let wrapper;
  let spyMutate;

  const defaultData = {
    dismissalReason: null,
  };

  const defaultMocks = {
    $apollo: {
      mutate: jest.fn().mockResolvedValue(),
    },
  };

  const dismissButton = () => wrapper.find(GlNewButton);
  const dismissMessage = () => wrapper.find({ ref: 'dismiss-message' });
  const formSelect = () => wrapper.find(GlFormSelect);

  const createComponent = ({ props = {}, data = defaultData, mocks = defaultMocks }) => {
    spyMutate = mocks.$apollo.mutate;
    wrapper = mount(SelectionSummary, {
      mocks: {
        ...defaultMocks,
        ...mocks,
      },
      propsData: {
        selectedVulnerabilities: [],
        ...props,
      },
      data: () => data,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when vulnerabilities are selected', () => {
    describe('it renders correctly', () => {
      beforeEach(() => {
        createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }] } });
      });

      it('returns the right message for one selected vulnerabilities', () => {
        expect(dismissMessage().text()).toBe('Dismiss 1 selected vulnerability as');
      });

      it('returns the right message for greater than one selected vulnerabilities', () => {
        createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }, { id: 'id_1' }] } });
        expect(dismissMessage().text()).toBe('Dismiss 2 selected vulnerabilities as');
      });
    });

    describe('dismiss button', () => {
      beforeEach(() => {
        createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }] } });
      });

      it('should have the button disabled if an option is not selected', () => {
        expect(dismissButton().attributes('disabled')).toBe('disabled');
      });

      it('should have the button enabled if a vulnerability is selected and an option is selected', () => {
        createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }] } });
        expect(wrapper.vm.dismissalReason).toBe(null);
        expect(wrapper.findAll('option').length).toBe(4);
        formSelect()
          .findAll('option')
          .at(1)
          .setSelected();
        formSelect().trigger('change');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.dismissalReason).toEqual(expect.any(String));
          expect(dismissButton().attributes('disabled')).toBe(undefined);
        });
      });
    });

    describe('clicking the dismiss vulnerability button', () => {
      beforeEach(() => {
        createComponent({
          props: { selectedVulnerabilities: [{ id: 'id_0' }, { id: 'id_1' }] },
          data: { dismissalReason: 'Will Not Fix' },
        });
      });

      it('should make an API request for each vulnerability', () => {
        dismissButton().trigger('submit');
        expect(spyMutate).toHaveBeenCalledTimes(2);
      });

      it('should show toast with the right message if all calls were successful', () => {
        dismissButton().trigger('submit');
        setImmediate(() => {
          // return wrapper.vm.$nextTick().then(() => {
          expect(toast).toHaveBeenCalledWith('2 vulnerabilities dismissed');
        });
      });

      it('should show flash with the right message if some calls failed', () => {
        createComponent({
          props: { selectedVulnerabilities: [{ id: 'id_0' }, { id: 'id_1' }] },
          data: { dismissalReason: 'Will Not Fix' },
          mocks: { $apollo: { mutate: jest.fn().mockRejectedValue() } },
        });
        dismissButton().trigger('submit');
        setImmediate(() => {
          expect(createFlash).toHaveBeenCalledWith(
            'There was an error dismissing the vulnerabilities.',
            'alert',
          );
        });
      });
    });
  });

  describe('when vulnerabilities are not selected', () => {
    beforeEach(() => {
      createComponent({});
    });
    it('should have the button disabled', () => {
      expect(dismissButton().attributes().disabled).toBe('disabled');
    });
  });
});
