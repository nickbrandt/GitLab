import Vue from 'vue';
import eventHub from '~/issuable/related_issues/event_hub';
import AddIssuableForm from '~/issuable/related_issues/components/add_issuable_form.vue';

const createComponent = (propsData = {}) => {
  const Component = Vue.extend(AddIssuableForm);

  const el = document.createElement('div');
  // Need to append to body to get focus tests working
  document.body.appendChild(el);

  return new Component({
    el,
    propsData,
  });
};

const issuable1 = {
  reference: 'foo/bar#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
};

describe('AddIssuableForm', () => {
  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('methods', () => {
    let addIssuableFormInputSpy;
    let addIssuableFormBlurSpy;
    let addIssuableFormIssuableRemoveRequestSpy;
    let addIssuableFormSubmitSpy;
    let addIssuableFormCancelSpy;

    beforeEach(() => {
      addIssuableFormInputSpy = jasmine.createSpy('spy');
      addIssuableFormBlurSpy = jasmine.createSpy('spy');
      addIssuableFormIssuableRemoveRequestSpy = jasmine.createSpy('spy');
      addIssuableFormSubmitSpy = jasmine.createSpy('spy');
      addIssuableFormCancelSpy = jasmine.createSpy('spy');
      spyOn(AddIssuableForm.methods, 'onInputWrapperClick').and.callThrough();
      eventHub.$on('addIssuableFormInput', addIssuableFormInputSpy);
      eventHub.$on('addIssuableFormBlur', addIssuableFormBlurSpy);
      eventHub.$on('addIssuableFormIssuableRemoveRequest', addIssuableFormIssuableRemoveRequestSpy);
      eventHub.$on('addIssuableFormSubmit', addIssuableFormSubmitSpy);
      eventHub.$on('addIssuableFormCancel', addIssuableFormCancelSpy);

      vm = createComponent({
        inputValue: '',
        addButtonLabel: 'Add issuable',
        pendingIssuables: [
          issuable1,
        ],
      });
    });

    afterEach(() => {
      eventHub.$off('addIssuableFormInput', addIssuableFormInputSpy);
      eventHub.$off('addIssuableFormBlur', addIssuableFormBlurSpy);
      eventHub.$off('addIssuableFormIssuableRemoveRequest', addIssuableFormIssuableRemoveRequestSpy);
      eventHub.$off('addIssuableFormSubmit', addIssuableFormSubmitSpy);
      eventHub.$off('addIssuableFormCancel', addIssuableFormCancelSpy);
    });

    it('when clicking somewhere on the input wrapper should focus the input', () => {
      expect(AddIssuableForm.methods.onInputWrapperClick).not.toHaveBeenCalled();

      vm.$refs['issuable-form-wrapper'].click();

      expect(AddIssuableForm.methods.onInputWrapperClick).toHaveBeenCalled();
      expect(document.activeElement).toEqual(vm.$refs.input);
    });

    it('when filling in the input', () => {
      expect(addIssuableFormInputSpy).not.toHaveBeenCalled();

      const newInputValue = 'filling in things';
      vm.$refs.input.value = newInputValue;
      vm.onInput();

      expect(addIssuableFormInputSpy).toHaveBeenCalledWith(newInputValue, newInputValue.length);
    });

    it('when blurring the input', () => {
      expect(addIssuableFormInputSpy).not.toHaveBeenCalled();

      const newInputValue = 'filling in things';
      vm.$refs.input.value = newInputValue;
      vm.onBlur();

      expect(addIssuableFormBlurSpy).toHaveBeenCalledWith(newInputValue);
    });

    it('when removing pending issuable token', () => {
      expect(addIssuableFormIssuableRemoveRequestSpy).not.toHaveBeenCalled();

      vm.onPendingIssuableRemoveRequest(issuable1.reference);

      expect(addIssuableFormIssuableRemoveRequestSpy).toHaveBeenCalledWith(issuable1.reference);
    });

    it('when submitting pending issues', () => {
      expect(addIssuableFormSubmitSpy).not.toHaveBeenCalled();

      vm.onFormSubmit();

      expect(addIssuableFormSubmitSpy).toHaveBeenCalled();
    });

    it('when canceling form to collapse', () => {
      expect(addIssuableFormCancelSpy).not.toHaveBeenCalled();

      vm.onFormCancel();

      expect(addIssuableFormCancelSpy).toHaveBeenCalled();
    });
  });
});
