const ACTIVE_CLASS = 'active';

/**
 * Modifies the tab element and its content based on whether it is currently active or not
 * @param {Object} tabElement DOM element to modify
 * @param {Boolean} isActive if the DOM element is currently active or not
 */
const modifyActiveClass = (tabElement, isActive = false) => {
  const action = isActive ? 'remove' : 'add';
  tabElement.classList[action](ACTIVE_CLASS);
  tabElement.setAttribute('aria-selected', !isActive);
  const tabContent = document.querySelector(tabElement.hash);
  tabContent.classList[action](ACTIVE_CLASS);
};

// This allows us to toggle between tabs that we've migrated from bootstrap
// Note: This ONLY works on elements that are created on page load
// You can follow this effort in the following epic
// https://gitlab.com/groups/gitlab-org/-/epics/3983
export default function initTabHandler() {
  const TAB_SELECTOR = '.gl-nav-tabs .nav-link';

  const elements = document.querySelectorAll(TAB_SELECTOR);
  elements.forEach((element) => {
    element.addEventListener('click', () => {
      if (element.classList.contains(ACTIVE_CLASS)) {
        // do nothing if already active
      } else {
        // modify previously active tab and content
        const prevActiveTab = document.querySelector(`${TAB_SELECTOR}.${ACTIVE_CLASS}`);
        modifyActiveClass(prevActiveTab, true);

        // modify newly active tab and content
        modifyActiveClass(element);
      }
    });
  });
}
