/**
 * Updates the tab content that is active
 * @param {String} contentSelector CSS selector for tab content
 * @param {Integer} currentTabIndex index of tab that is selected
 */
export const updateActiveTabContent = (contentSelector, currentTabIndex) => {
  const tabContentNodes = document.querySelectorAll(contentSelector);

  if (currentTabIndex > tabContentNodes.length - 1) {
    return;
  }

  tabContentNodes.forEach((tabContent, index) => {
    if (currentTabIndex === index) {
      tabContent.classList.add('active');
    } else {
      tabContent.classList.remove('active');
    }
  });
};
