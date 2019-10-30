import Vue from 'vue';
import { PathIdSeparator } from 'ee/related_issues/constants';
import addIssuableForm from 'ee/related_issues/components/add_issuable_form.vue';

const issuable1 = {
  id: 200,
  reference: 'foo/bar#123',
  displayReference: '#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
};

const issuable2 = {
  id: 201,
  reference: 'foo/bar#124',
  displayReference: '#124',
  title: 'some other thing',
  path: '/foo/bar/issues/124',
  state: 'opened',
};

const pathIdSeparator = PathIdSeparator.Issue;

describe('AddIssuableForm', () => {
  let AddIssuableForm;
  let vm;

  beforeEach(() => {
    AddIssuableForm = Vue.extend(addIssuableForm);
  });

  afterEach(() => {
    if (vm) {
      // Avoid any NPE errors from `@blur` being called
      // after `vm.$destroy` in tests, https://github.com/vuejs/vue/issues/5829
      document.activeElement.blur();

      vm.$destroy();
    }
  });

  describe('with data', () => {
    describe('without references', () => {
      describe('without any input text', () => {
        beforeEach(() => {
          vm = new AddIssuableForm({
            propsData: {
              inputValue: '',
              pendingReferences: [],
              pathIdSeparator,
            },
          }).$mount();
        });

        it('should have disabled submit button', () => {
          expect(vm.$refs.addButton.disabled).toBe(true);
          expect(vm.$refs.loadingIcon).toBeUndefined();
        });
      });

      describe('with input text', () => {
        beforeEach(() => {
          vm = new AddIssuableForm({
            propsData: {
              inputValue: 'foo',
              pendingReferences: [],
              pathIdSeparator,
            },
          }).$mount();
        });

        it('should not have disabled submit button', () => {
          expect(vm.$refs.addButton.disabled).toBe(false);
        });
      });
    });

    describe('with references', () => {
      const inputValue = 'foo #123';

      beforeEach(() => {
        vm = new AddIssuableForm({
          propsData: {
            inputValue,
            pendingReferences: [issuable1.reference, issuable2.reference],
            pathIdSeparator,
          },
        }).$mount();
      });

      it('should put input value in place', () => {
        expect(vm.$el.querySelector('.js-add-issuable-form-input').value).toEqual(inputValue);
      });

      it('should render pending issuables items', () => {
        expect(vm.$el.querySelectorAll('.js-add-issuable-form-token-list-item').length).toEqual(2);
      });

      it('should not have disabled submit button', () => {
        expect(vm.$refs.addButton.disabled).toBe(false);
      });
    });

    it('when submitting pending issues', () => {
      vm = new AddIssuableForm({
        propsData: {
          inputValue: 'foo #123',
          pendingReferences: [issuable1.reference, issuable2.reference],
          pathIdSeparator,
        },
      });
      vm.$mount();

      spyOn(vm, '$emit');
      const newInputValue = 'filling in things';
      const inputEl = vm.$el.querySelector('.js-add-issuable-form-input');
      inputEl.value = newInputValue;
      vm.onFormSubmit();

      expect(vm.$emit).toHaveBeenCalledWith('addIssuableFormSubmit', newInputValue);
    });

    it('when canceling form to collapse', () => {
      spyOn(vm, '$emit');
      vm.onFormCancel();

      expect(vm.$emit).toHaveBeenCalledWith('addIssuableFormCancel');
    });
  });
});
