import { shallowMount } from '@vue/test-utils';
import validation, { initForm } from '~/vue_shared/directives/validation';

describe('validation directive', () => {
  let wrapper;

  const createComponentFactory = ({ inputAttributes, data, inputValidation }) => {
    const defaultInputAttributes = {
      type: 'text',
      required: true,
    };

    const component = {
      directives: {
        validation: validation(),
      },
      data() {
        return {
          attributes: inputAttributes || defaultInputAttributes,
          ...data,
        };
      },
      template: `
        <form>
          <input v-validation:[${inputValidation}] name="exampleField" v-bind="attributes" />
        </form>
      `,
    };

    wrapper = shallowMount(component, { attachTo: document.body });
  };

  const createComponent = ({ inputAttributes, showValidation } = {}) =>
    createComponentFactory({
      inputAttributes,
      inputValidation: 'showValidation',
      data: {
        showValidation,
        form: {
          state: null,
          fields: {
            exampleField: {
              state: null,
              feedback: '',
            },
          },
        },
      },
    });

  const createComponentWithInitForm = ({ inputAttributes } = {}) =>
    createComponentFactory({
      inputAttributes,
      inputValidation: 'form.showValidation',
      data: {
        form: initForm({
          fields: {
            exampleField: {
              state: null,
              value: 'lorem',
            },
          },
        }),
      },
    });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const getFormData = () => wrapper.vm.form;
  const findForm = () => wrapper.find('form');
  const findInput = () => wrapper.find('input');

  describe.each([true, false])(
    'with fields untouched and "showValidation" set to "%s"',
    (showValidation) => {
      beforeEach(() => {
        createComponent({ showValidation });
      });

      it('sets the fields validity correctly', () => {
        expect(getFormData().fields.exampleField).toEqual({
          state: showValidation ? false : null,
          feedback: showValidation ? expect.any(String) : '',
        });
      });

      it('sets the form validity correctly', () => {
        expect(getFormData().state).toBe(false);
      });
    },
  );

  describe.each`
    inputAttributes                       | validValue          | invalidValue
    ${{ required: true }}                 | ${'foo'}            | ${''}
    ${{ type: 'url' }}                    | ${'http://foo.com'} | ${'foo'}
    ${{ type: 'number', min: 1, max: 5 }} | ${3}                | ${0}
    ${{ type: 'number', min: 1, max: 5 }} | ${3}                | ${6}
    ${{ pattern: 'foo|bar' }}             | ${'bar'}            | ${'quz'}
  `(
    'with input-attributes set to $inputAttributes',
    ({ inputAttributes, validValue, invalidValue }) => {
      const setValueAndTriggerValidation = (value) => {
        const input = findInput();
        input.setValue(value);
        input.trigger('blur');
      };

      beforeEach(() => {
        createComponent({ inputAttributes });
      });

      describe('with valid value', () => {
        beforeEach(() => {
          setValueAndTriggerValidation(validValue);
        });

        it('sets the field to be valid', () => {
          expect(getFormData().fields.exampleField).toEqual({
            state: true,
            feedback: '',
          });
        });

        it('sets the form to be valid', () => {
          expect(getFormData().state).toBe(true);
        });
      });

      describe('with invalid value', () => {
        beforeEach(() => {
          setValueAndTriggerValidation(invalidValue);
        });

        it('sets the field to be invalid', () => {
          expect(getFormData().fields.exampleField).toEqual({
            state: false,
            feedback: expect.any(String),
          });
          expect(getFormData().fields.exampleField.feedback.length).toBeGreaterThan(0);
        });

        it('sets the form to be invalid', () => {
          expect(getFormData().state).toBe(false);
        });

        it('sets focus on the first invalid input when the form is submitted', () => {
          findForm().trigger('submit');
          expect(findInput().element).toBe(document.activeElement);
        });
      });
    },
  );

  describe('component using initForm', () => {
    it('sets the form fields correctly', () => {
      createComponentWithInitForm();

      expect(getFormData().state).toBe(false);
      expect(getFormData().showValidation).toBe(false);

      expect(getFormData().fields.exampleField).toMatchObject({
        value: 'lorem',
        state: null,
        required: true,
        feedback: expect.any(String),
      });
    });
  });
});

describe('initForm', () => {
  const MOCK_FORM = {
    fields: {
      name: {
        value: 'lorem',
      },
      description: {
        value: 'ipsum',
        required: false,
        skipValidation: true,
      },
    },
  };

  it('returns form object', () => {
    expect(initForm(MOCK_FORM)).toMatchObject({
      state: false,
      showValidation: false,
      fields: {
        name: { value: 'lorem', required: true, state: null, feedback: null },
        description: { value: 'ipsum', required: false, state: true, feedback: null },
      },
    });
  });

  it('returns form object with additional parameters', () => {
    const customFormObject = {
      foo: {
        bar: 'lorem',
      },
    };

    const form = {
      ...MOCK_FORM,
      ...customFormObject,
    };

    expect(initForm(form)).toMatchObject({
      state: false,
      showValidation: false,
      fields: {
        name: { value: 'lorem', required: true, state: null, feedback: null },
        description: { value: 'ipsum', required: false, state: true, feedback: null },
      },
      ...customFormObject,
    });
  });

  it('can override existing state and showValidation values', () => {
    const form = {
      ...MOCK_FORM,
      state: true,
      showValidation: true,
    };

    expect(initForm(form)).toMatchObject({
      state: true,
      showValidation: true,
      fields: {
        name: { value: 'lorem', required: true, state: null, feedback: null },
        description: { value: 'ipsum', required: false, state: true, feedback: null },
      },
    });
  });
});
