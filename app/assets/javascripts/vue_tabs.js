import Vue from 'vue';
import { updateActiveTabContent } from './vue_tabs_content_selector';

const mountVueTabs = ({
  rootSelector,
  component,
  contentSelector = '.gitlab-tab-content .tab-pane',
}) => {
  const el = document.querySelector(rootSelector);

  if (!el) {
    return null;
  }

  const theme = window.gon?.user_application_theme;

  return new Vue({
    el,
    render: (h) =>
      h(component, {
        attrs: { theme },
        on: {
          input: (current) => updateActiveTabContent(contentSelector, current),
        },
      }),
  });
};

export default mountVueTabs;
