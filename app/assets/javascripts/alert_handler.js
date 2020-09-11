// This allows us to dismiss alerts and banners that we've migrated from bootstrap
// Note: This ONLY works on elements that are created on page load
// You can follow this effort in the following epic
// https://gitlab.com/groups/gitlab-org/-/epics/4070

export default function initAlertHandler() {
  const DISMISSIBLE_SELECTORS = ['.gl-alert', '.gl-banner'];
  const CLOSE_SELECTOR = '[aria-label="Dismiss"]';

  DISMISSIBLE_SELECTORS.forEach(selector => {
    const elements = document.querySelectorAll(selector);
    elements.forEach(element =>
      element.querySelector(CLOSE_SELECTOR).addEventListener('click', () => element.remove()),
    );
  });
}
