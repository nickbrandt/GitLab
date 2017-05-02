import Vue from 'vue';
import eventHub from '~/issuable/related_issues/event_hub';
import AddIssuableForm from '~/issuable/related_issues/components/add_issuable_form.vue';

const createComponent = (propsData = {}) => {
  const Component = Vue.extend(AddIssuableForm);

  return new Component({
    el: document.createElement('div'),
    propsData,
  });
};

fdescribe('AddIssuableForm', () => {
  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('', () => {

  });


  describe('methods', () => {
    let addIssuableFormInputSpy;
    let addIssuableFormIssuableRemoveRequestSpy;
    let addIssuableFormSubmitSpy;
    let addIssuableFormCancelSpy;

    beforeEach(() => {
      vm = createComponent({
        inputValue: '',
        addButtonLabel: 'Add issuable',
      });
      addIssuableFormInputSpy = jasmine.createSpy('spy');
      addIssuableFormIssuableRemoveRequestSpy = jasmine.createSpy('spy');
      addIssuableFormSubmitSpy = jasmine.createSpy('spy');
      addIssuableFormCancelSpy = jasmine.createSpy('spy');
      eventHub.$on('addIssuableFormInput', addIssuableFormInputSpy);
      eventHub.$on('addIssuableFormIssuableRemoveRequest', addIssuableFormIssuableRemoveRequestSpy);
      eventHub.$on('addIssuableFormSubmit', addIssuableFormSubmitSpy);
      eventHub.$on('addIssuableFormCancel', addIssuableFormCancelSpy);
    });

    afterEach(() => {
      eventHub.$off('addIssuableFormInput', addIssuableFormInputSpy);
      eventHub.$off('addIssuableFormIssuableRemoveRequest', addIssuableFormIssuableRemoveRequestSpy);
      eventHub.$off('addIssuableFormSubmit', addIssuableFormSubmitSpy);
      eventHub.$off('addIssuableFormCancel', addIssuableFormCancelSpy);
    });

    it('when filling in the input', () => {
      expect(addIssuableFormInputSpy).not.toHaveBeenCalled();

      const newInputValue = 'filling in things';
      vm.$refs.input.value = newInputValue;
      vm.onInput();

      expect(addIssuableFormInputSpy).toHaveBeenCalledWith(newInputValue);
    });
  });
});
