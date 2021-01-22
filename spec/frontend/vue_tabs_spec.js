import initVueTabs from '~/vue_tabs';

const createComponent = (className) => {
  const div = document.createElement('div');
  div.classList += className;
  document.body.appendChild(div);
};

describe('InitVueTab', () => {
  it('renders if rootSelector is found', () => {
    const className = 'js-test';
    createComponent(className);
    const created = initVueTabs({ rootSelector: `.${className}` });
    expect(created).not.toBe(null);
  });

  it('returns null if rootSelector is not found', () => {
    createComponent();
    const created = initVueTabs({ rootSelector: '.js-test' });
    expect(created).toBe(null);
  });
});
