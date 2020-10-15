import { merge } from 'lodash';
import { s__ } from '~/locale';

export const defaultValidationMessages = {
  urlTypeMismatch: {
    check: el => el.type === 'url' && el.validity?.typeMismatch,
    message: s__('Please enter a valid URL format, ex: http://www.example.com/home'),
  },
};

const getCustomValidationMessage = (feedback, el) =>
  Object.values(feedback).find(f => f.check(el))?.message || '';

const focusFirstInvalidInput = e => {
  const { target: formEl } = e;
  const invalidInput = formEl.querySelector('input:invalid');

  if (invalidInput) {
    invalidInput.focus();
  }
};

const createValidator = (context, validationMessages) => el => {
  const { form } = context;
  const { name } = el;

  const isValid = el.checkValidity();

  form.fields[name].state = isValid;
  form.fields[name].feedback =
    getCustomValidationMessage(validationMessages, el) || el.validationMessage;

  form.state = !Object.values(form.fields).some(field => field.state === false);

  return isValid;
};

export default function(customValidationMessages = {}) {
  const feedback = merge(defaultValidationMessages, customValidationMessages);
  const elDataMap = new WeakMap();

  return {
    inserted(el, binding, { context }) {
      const { arg: showGlobalValidation } = binding;
      const { form: formEl } = el;

      const validate = createValidator(context, feedback);
      const elData = { validate, isTouched: false, isBlurred: false };
      elDataMap.set(el, elData);

      el.addEventListener('input', function markAsTouched() {
        elData.isTouched = true;
        el.removeEventListener('input', markAsTouched);
      });

      el.addEventListener('blur', function markAsBlurred({ target }) {
        if (elData.isTouched) {
          elData.isBlurred = true;
          validate(target);
          // this event handler can be removed, since the live-feedback now takes over
          el.removeEventListener('blur', markAsBlurred);
        }
      });

      if (formEl) {
        formEl.addEventListener('submit', focusFirstInvalidInput);
      }

      if (showGlobalValidation) {
        validate(el);
      }
    },
    update(el, binding) {
      const { arg: showGlobalValidation } = binding;
      const { validate, isTouched, isBlurred } = elDataMap.get(el);

      // trigger live-feedback once the element has been touched an clicked way from
      if (showGlobalValidation || (isTouched && isBlurred)) {
        validate(el);
      }
    },
  };
}
