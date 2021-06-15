import { updateActiveTabContent } from '~/vue_tabs_content_selector';

const firstContentSelector = 'gitlab-tab-content';
const secondContentSelector = 'tab-pane';
const addContent = (customClass) => {
  const div = document.createElement('div');
  div.classList += `${secondContentSelector} ${customClass}`;
  return div;
};
const findTabPanes = () => document.querySelectorAll('.gitlab-tab-content .tab-pane');
const findTabPaneAt = (index) => [...findTabPanes()][index];

const expectNoClassActive = (tabPane) => {
  expect(tabPane.className).not.toContain('active');
};
const expectClassActive = (tabPane) => {
  expect(tabPane.className).toContain('active');
};

const createComponent = (additionalClass) => {
  const tabContent = document.createElement('div');
  tabContent.classList += firstContentSelector;
  tabContent.appendChild(addContent(`first ${additionalClass}`));
  tabContent.appendChild(addContent('second'));
  document.body.appendChild(tabContent);
};

afterEach(() => {
  document.body.innerHTML = '';
});

describe('updateActiveTabContent', () => {
  it("adds the 'active' class to the selected tab's content", async () => {
    createComponent();
    expectNoClassActive(findTabPaneAt(0));
    updateActiveTabContent('.gitlab-tab-content .tab-pane', 0);
    expectClassActive(findTabPaneAt(0));
  });

  it("removes the 'active' class to the unselected tab's content", async () => {
    createComponent('active');
    expectClassActive(findTabPaneAt(0));
    updateActiveTabContent('.gitlab-tab-content .tab-pane', 1);
    expectNoClassActive(findTabPaneAt(0));
    expectClassActive(findTabPaneAt(1));
  });

  it('does not update any classes if the current content is reselected', async () => {
    createComponent('active');
    expectClassActive(findTabPaneAt(0));
    updateActiveTabContent('.gitlab-tab-content .tab-pane', 0);
    expectClassActive(findTabPaneAt(0));
    expectNoClassActive(findTabPaneAt(1));
  });

  it('does not update any classes if the index is greater than the number of nodes', async () => {
    createComponent('active');
    expectClassActive(findTabPaneAt(0));
    updateActiveTabContent('.gitlab-tab-content .tab-pane', 2);
    expectClassActive(findTabPaneAt(0));
    expectNoClassActive(findTabPaneAt(1));
  });
});
