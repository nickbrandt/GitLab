import { mount, shallowMount } from '@vue/test-utils';
import { issuableTypesMap, PathIdSeparator } from '~/related_issues/constants';
import AddIssuableForm from '~/related_issues/components/add_issuable_form.vue';

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

const findRadioInputs = wrapper => wrapper.findAll('[name="linked-issue-type-radio"]');

const constructWrapper = props => {
  return shallowMount(AddIssuableForm, {
    propsData: {
      inputValue: '',
      pendingReferences: [],
      pathIdSeparator,
      ...props,
    },
  });
};

describe('AddIssuableForm', () => {
  let wrapper;

  afterEach(() => {
    // Jest doesn't blur an item even if it is destroyed,
    // so blur the input manually after each test
    const input = findFormInput(wrapper);
    if (input) input.blur();

    wrapper.destroy();
  });

  describe('with data', () => {
    describe('without references', () => {
      describe('without any input text', () => {
        beforeEach(() => {
          wrapper = shallowMount(AddIssuableForm, {
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
          wrapper = shallowMount(AddIssuableForm, {
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

    describe('when issuable type is "issue"', () => {
      beforeEach(() => {
        wrapper = mount(AddIssuableForm, {
          propsData: {
            inputValue: '',
            issuableType: issuableTypesMap.ISSUE,
            pathIdSeparator,
            pendingReferences: [],
          },
        });
      });

      it('does not show radio inputs', () => {
        expect(findRadioInputs(wrapper).length).toBe(0);
      });
    });
  });

  describe('computed', () => {
    describe('transformedAutocompleteSources', () => {
      const autoCompleteSources = {
        issues: 'http://localhost/autocomplete/issues',
        epics: 'http://localhost/autocomplete/epics',
      };

      it('returns autocomplete object', () => {
        wrapper = constructWrapper({
          autoCompleteSources,
        });

        expect(wrapper.vm.transformedAutocompleteSources).toBe(autoCompleteSources);

        wrapper = constructWrapper({
          autoCompleteSources,
          confidential: false,
        });

        expect(wrapper.vm.transformedAutocompleteSources).toBe(autoCompleteSources);
      });

      it('returns autocomplete sources with query `confidential_only`, when it is confidential', () => {
        wrapper = constructWrapper({
          autoCompleteSources,
          confidential: true,
        });

        const actualSources = wrapper.vm.transformedAutocompleteSources;

        expect(actualSources.epics).toContain('?confidential_only=true');
        expect(actualSources.issues).toContain('?confidential_only=true');
      });
    });
  });
});
