import { mount } from '@vue/test-utils';
import SelectionSummary from 'ee//security_dashboard/components/selection_summary.vue';

describe('Selection Summary component', () => {
  let wrapper;

  const defaultData = {
    dismissalReason: null,
  };

  const createComponent = ({ props = {}, data = defaultData }) => {
    wrapper = mount(SelectionSummary, {
      propsData: {
        refetchVulnerabilities: jest.fn(),
        deselectAllVulnerabilities: jest.fn(),
        selectedVulnerabilities: [],
        ...props,
      },
      data: () => data,
    });
  };

  beforeEach(() => {
    createComponent({});
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('selectedVulnerabilitiesCount', () => {
      it('returns the length if this.selectedVulnerabilities is empty', () => {
        expect(wrapper.vm.selectedVulnerabilitiesCount).toBe(0);
      });

      it('returns the length if this.selectedVulnerabilities is not empty', () => {
        createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }] } });
        expect(wrapper.vm.selectedVulnerabilitiesCount).toBe(1);
      });
    });

    describe('canDismissVulnerability', () => {
      it('returns true if there is a dismissal reason and a selectedVulnerabilitiesCount greater than zero', () => {
        createComponent({
          props: { selectedVulnerabilities: [{ id: 'id_0' }] },
          data: { dismissalReason: 'Will Not Fix' },
        });
        expect(wrapper.vm.canDismissVulnerability).toBe(true);
      });

      it('returns false if there is a dismissal reason and not a selectedVulnerabilitiesCount greater than zero', () => {
        createComponent({
          props: { selectedVulnerabilities: [] },
          data: { dismissalReason: 'Will Not Fix' },
        });
        expect(wrapper.vm.canDismissVulnerability).toBe(false);
      });

      it('returns false if there is not a dismissal reason and a selectedVulnerabilitiesCount greater than zero', () => {
        createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }] } });
        expect(wrapper.vm.canDismissVulnerability).toBe(false);
      });

      it('returns false if there is not a dismissal reason and not a selectedVulnerabilitiesCount greater than zero', () => {
        expect(wrapper.vm.canDismissVulnerability).toBe(false);
      });
    });

    describe('message', () => {
      it('returns the right message for zero selected vulnerabilities', () => {
        expect(wrapper.vm.message).toBe('Dismiss 0 selected vulnerabilities as');
      });

      it('returns the right message for one selected vulnerabilities', () => {
        createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }] } });
        expect(wrapper.vm.message).toBe('Dismiss 1 selected vulnerability as');
      });

      it('returns the right message for greater than one selected vulnerabilities', () => {
        createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }, { id: 'id_1' }] } });
        expect(wrapper.vm.message).toBe('Dismiss 2 selected vulnerabilities as');
      });
    });
  });

  describe('methods', () => {
    describe('getSuccessMessage', () => {
      it('returns the right message for zero selected vulnerabilities', () => {
        expect(wrapper.vm.dismissalSuccessMessage()).toBe('0 vulnerabilities dismissed');
      });

      it('returns the right message for one selected vulnerabilities', () => {
        createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }] } });
        expect(wrapper.vm.dismissalSuccessMessage()).toBe('1 vulnerability dismissed');
      });

      it('returns the right message for greater than one selected vulnerabilities', () => {
        createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }, { id: 'id_1' }] } });
        expect(wrapper.vm.dismissalSuccessMessage()).toBe('2 vulnerabilities dismissed');
      });
    });
    describe('handleDismiss', () => {
      it('does call dismissSelectedVulnerabilities when canDismissVulnerability is true', () => {
        createComponent({
          props: { selectedVulnerabilities: [{ id: 'id_0' }] },
          data: { dismissalReason: 'Will Not Fix' },
        });
        const spy = jest.spyOn(wrapper.vm, 'dismissSelectedVulnerabilities').mockImplementation();
        wrapper.vm.handleDismiss();
        expect(spy).toHaveBeenCalled();
      });

      it('does not call dismissSelectedVulnerabilities when canDismissVulnerability is false', () => {
        const spy = jest.spyOn(wrapper.vm, 'dismissSelectedVulnerabilities');
        wrapper.vm.handleDismiss();
        expect(spy).not.toHaveBeenCalled();
      });
    });
  });
});
