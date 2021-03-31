import { updateActiveTabContent } from '~/lib/utils/tabs_utils';

const firstContentSelector = 'gitlab-tab-content';
const secondContentSelector = 'tab-pane';
const addContent = (customClass) => {
  const div = document.createElement('div');
  div.classList += `${secondContentSelector} ${customClass}`;
  return div;
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
    expect(
      [...document.querySelectorAll('.gitlab-tab-content .tab-pane')][0].className,
    ).not.toContain('active');
    updateActiveTabContent('.gitlab-tab-content .tab-pane', 0);
    expect([...document.querySelectorAll('.gitlab-tab-content .tab-pane')][0].className).toContain(
      'active',
    );
  });

  it("removes the 'active' class to the unselected tab's content", async () => {
    createComponent('active');
    expect([...document.querySelectorAll('.gitlab-tab-content .tab-pane')][0].className).toContain(
      'active',
    );
    updateActiveTabContent('.gitlab-tab-content .tab-pane', 1);
    expect(
      [...document.querySelectorAll('.gitlab-tab-content .tab-pane')][0].className,
    ).not.toContain('active');
    expect([...document.querySelectorAll('.gitlab-tab-content .tab-pane')][1].className).toContain(
      'active',
    );
  });

  it('does not update any classes if the current content is reselected', async () => {
    createComponent('active');
    expect([...document.querySelectorAll('.gitlab-tab-content .tab-pane')][0].className).toContain(
      'active',
    );
    updateActiveTabContent('.gitlab-tab-content .tab-pane', 0);
    expect([...document.querySelectorAll('.gitlab-tab-content .tab-pane')][0].className).toContain(
      'active',
    );
    expect(
      [...document.querySelectorAll('.gitlab-tab-content .tab-pane')][1].className,
    ).not.toContain('active');
  });

  it('does not update any classes if the index is greater than the number of nodes', async () => {
    createComponent('active');
    expect([...document.querySelectorAll('.gitlab-tab-content .tab-pane')][0].className).toContain(
      'active',
    );
    updateActiveTabContent('.gitlab-tab-content .tab-pane', 2);
    expect([...document.querySelectorAll('.gitlab-tab-content .tab-pane')][0].className).toContain(
      'active',
    );
    expect(
      [...document.querySelectorAll('.gitlab-tab-content .tab-pane')][1].className,
    ).not.toContain('active');
  });
});
