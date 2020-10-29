import { merge } from 'lodash';
import { s__ } from '~/locale';

/**
 * Validation messages will take priority based on the property order.
 * For example:
 * { valueMissing: {...}, urlTypeMismatch: {...} }
 *
 * `valueMissing` will be displayed the user has entered a value
 *  after that, if the input is not a valid URL then `urlTypeMismatch` will show
 */
const defaultFeedbackMap = {
  valueMissing: {
    isInvalid: el => el.validity?.valueMissing,
    message: s__('Please fill out this field.'),
  },
  urlTypeMismatch: {
    isInvalid: el => el.type === 'url' && el.validity?.typeMismatch,
    message: s__('Please enter a valid URL format, ex: http://www.example.com/home'),
  },
};

const getFeedbackForElement = (feedbackMap, el) =>
  Object.values(feedbackMap).find(f => f.isInvalid(el))?.message || el.validationMessage;

const focusFirstInvalidInput = e => {
  const { target: formEl } = e;
  const invalidInput = formEl.querySelector('input:invalid');

  if (invalidInput) {
    invalidInput.focus();
  }
};

const isEveryFieldValid = form => Object.values(form.fields).every(({ state }) => state === true);

const createValidator = (context, feedbackMap) => el => {
  const { form } = context;
  const { name } = el;
  const formField = form.fields[name];
  const isValid = el.checkValidity();

  formField.state = isValid;
  formField.feedback = getFeedbackForElement(feedbackMap, el);

  form.state = isEveryFieldValid(form);
};

export default function(customFeedbackMap = {}) {
  const feedbackMap = merge(defaultFeedbackMap, customFeedbackMap);
  const elDataMap = new WeakMap();

  return {
    inserted(el, binding, { context }) {
      const { arg: showGlobalValidation } = binding;
      const { form: formEl } = el;

      const validate = createValidator(context, feedbackMap);
      const elData = { validate, isTouched: false, isBlurred: false };

      elDataMap.set(el, elData);

      el.addEventListener('input', function markAsTouched() {
        elData.isTouched = true;
        // once the element has been marked as touched we can stop listening on the 'input' event
        el.removeEventListener('input', markAsTouched);
      });

      el.addEventListener('blur', function markAsBlurred({ target }) {
        if (elData.isTouched) {
          elData.isBlurred = true;
          validate(target);
          // this event handler can be removed, since the live-feedback in `update` takes over
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
