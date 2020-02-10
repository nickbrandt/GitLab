const hide = el => el.classList.add('d-none');

const show = el => el.classList.remove('d-none');

const setupCollapsibleInput = el => {
  const collapsedEl = el.querySelector('.js-collapsed');
  const expandedEl = el.querySelector('.js-expanded');
  const collapsedInputEl = collapsedEl.querySelector('textarea,input,select');
  const expandedInputEl = expandedEl.querySelector('textarea,input,select');

  const collapse = () => {
    hide(expandedEl);
    show(collapsedEl);
  };

  const expand = () => {
    hide(collapsedEl);
    show(expandedEl);
  };

  collapsedInputEl.addEventListener('focus', () => {
    expand();
    expandedInputEl.focus();
  });

  expandedEl.addEventListener('focusout', e => {
    if (!expandedInputEl.value) {
      collapse();
    }
  });
};

export default () =>
  Array.from(document.querySelectorAll('.js-collapsible-input')).map(setupCollapsibleInput);
