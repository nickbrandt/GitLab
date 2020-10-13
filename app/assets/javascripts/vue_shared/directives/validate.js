let handler;

const isURLTypeMismatch = el => el.type === 'url' && el.validity.typeMismatch;

const getFeedback = el => {
  return isURLTypeMismatch(el) ? 'UUUPs... :( :( ' : el.validationMessage;
};

export default {
  // called once, when the directive is first bound to the element, one-time setup
  bind(el, binding) {
    const { value, modifiers } = binding;

    handler = () => {
      value.state = el.checkValidity();
      value.feedback = getFeedback(el);
    };

    // el will be form element
    // attach event listener (input or blur? or customizable?)
    el.addEventListener(modifiers.blur ? 'blur' : 'input', handler);
  },
  // called once, cleanup work
  unbind(el) {
    el.removeEventListener('input', handler);
  },
};
