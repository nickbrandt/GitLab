import { mount } from '@vue/test-utils';
import { linkedIssueTypesMap, PathIdSeparator } from 'ee/related_issues/constants';
import AddIssuableForm from 'ee/related_issues/components/add_issuable_form.vue';

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

const findFormInput = wrapper => wrapper.find('.js-add-issuable-form-input').element;

const findRadioInput = (inputs, value) => inputs.filter(input => input.element.value === value)[0];

describe('AddIssuableForm', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with data', () => {
    describe('without references', () => {
      describe('without any input text', () => {
        beforeEach(() => {
          wrapper = mount(AddIssuableForm, {
            propsData: {
              inputValue: '',
              pendingReferences: [],
              pathIdSeparator,
            },
          });
        });

        it('should have disabled submit button', () => {
          expect(wrapper.vm.$refs.addButton.disabled).toBe(true);
          expect(wrapper.vm.$refs.loadingIcon).toBeUndefined();
        });
      });

      describe('with input text', () => {
        beforeEach(() => {
          wrapper = mount(AddIssuableForm, {
            propsData: {
              inputValue: 'foo',
              pendingReferences: [],
              pathIdSeparator,
            },
          });
        });

        it('should not have disabled submit button', () => {
          expect(wrapper.vm.$refs.addButton.disabled).toBe(false);
        });
      });
    });

    describe('with references', () => {
      const inputValue = 'foo #123';

      beforeEach(() => {
        wrapper = mount(AddIssuableForm, {
          propsData: {
            inputValue,
            pendingReferences: [issuable1.reference, issuable2.reference],
            pathIdSeparator,
          },
        });
      });

      it('should put input value in place', () => {
        expect(findFormInput(wrapper).value).toEqual(inputValue);
      });

      it('should render pending issuables items', () => {
        expect(wrapper.findAll('.js-add-issuable-form-token-list-item').length).toEqual(2);
      });

      it('should not have disabled submit button', () => {
        expect(wrapper.vm.$refs.addButton.disabled).toBe(false);
      });
    });

    it('should emit the `addIssuableFormSubmit` event when submitting pending issues', () => {
      wrapper = mount(AddIssuableForm, {
        propsData: {
          inputValue: 'foo #123',
          pendingReferences: [issuable1.reference, issuable2.reference],
          pathIdSeparator,
        },
      });

      spyOn(wrapper.vm, '$emit');
      const newInputValue = 'filling in things';
      const inputEl = findFormInput(wrapper);
      inputEl.value = newInputValue;
      wrapper.vm.onFormSubmit();

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('addIssuableFormSubmit', {
        pendingReferences: newInputValue,
        linkedIssueType: linkedIssueTypesMap.RELATES_TO,
      });
    });

    it('should emit the `addIssuableFormCancel` event when canceling form to collapse', () => {
      spyOn(wrapper.vm, '$emit');
      wrapper.vm.onFormCancel();

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('addIssuableFormCancel');
    });
  });

  describe('with :issue_link_types feature flag on', () => {
    beforeEach(() => {
      wrapper = mount(AddIssuableForm, {
        propsData: {
          inputValue: '',
          pendingReferences: [],
          pathIdSeparator,
        },
        provide: {
          glFeatures: {
            issueLinkTypes: true,
          },
        },
      });
    });

    describe('radio buttons', () => {
      let radioInputs;

      beforeEach(() => {
        radioInputs = wrapper.findAll('[name="linked-issue-type-radio"]');
      });

      it('shows "relates to" option', () => {
        expect(findRadioInput(radioInputs, linkedIssueTypesMap.RELATES_TO)).not.toBeNull();
      });

      it('shows "blocks" option', () => {
        expect(findRadioInput(radioInputs, linkedIssueTypesMap.BLOCKS)).not.toBeNull();
      });

      it('shows "is blocked by" option', () => {
        expect(findRadioInput(radioInputs, linkedIssueTypesMap.IS_BLOCKED_BY)).not.toBeNull();
      });

      it('shows 3 options in total', () => {
        expect(radioInputs.length).toBe(3);
      });
    });

    describe('when the form is submitted', () => {
      it('emits an event with a "relates_to" link type when the "relates to" radio input selected', done => {
        spyOn(wrapper.vm, '$emit');

        wrapper.vm.linkedIssueType = linkedIssueTypesMap.RELATES_TO;
        wrapper.vm.onFormSubmit();

        wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.$emit).toHaveBeenCalledWith('addIssuableFormSubmit', {
            pendingReferences: '',
            linkedIssueType: linkedIssueTypesMap.RELATES_TO,
          });
          done();
        });
      });

      it('emits an event with a "blocks" link type when the "blocks" radio input selected', done => {
        spyOn(wrapper.vm, '$emit');

        wrapper.vm.linkedIssueType = linkedIssueTypesMap.BLOCKS;
        wrapper.vm.onFormSubmit();

        wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.$emit).toHaveBeenCalledWith('addIssuableFormSubmit', {
            pendingReferences: '',
            linkedIssueType: linkedIssueTypesMap.BLOCKS,
          });
          done();
        });
      });

      it('emits an event with a "is_blocked_by" link type when the "is blocked by" radio input selected', done => {
        spyOn(wrapper.vm, '$emit');

        wrapper.vm.linkedIssueType = linkedIssueTypesMap.IS_BLOCKED_BY;
        wrapper.vm.onFormSubmit();

        wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.$emit).toHaveBeenCalledWith('addIssuableFormSubmit', {
            pendingReferences: '',
            linkedIssueType: linkedIssueTypesMap.IS_BLOCKED_BY,
          });
          done();
        });
      });

      it('shows error message when error is present', done => {
        const itemAddFailureMessage = 'Something went wrong while submitting.';
        wrapper.setProps({
          hasError: true,
          itemAddFailureMessage,
        });

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find('.gl-field-error').exists()).toBe(true);
          expect(wrapper.find('.gl-field-error').text()).toContain(itemAddFailureMessage);
          done();
        });
      });
    });
  });
});
