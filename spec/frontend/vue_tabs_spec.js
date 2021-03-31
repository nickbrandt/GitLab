import initVueTabs from '~/vue_tabs';

const createComponent = (className) => {
  const tabs = document.createElement('div');
  tabs.classList += className;
  document.body.appendChild(tabs);
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
