import Vue from 'vue';

const mountVueTabs = ({
  rootSelector,
  component,
  contentSelector = '.gitlab-tab-content .tab-pane',
}) => {
  const el = document.querySelector(rootSelector);

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    render: (h) =>
      h(component, {
        on: {
          input: (current) => {
            document.querySelectorAll(contentSelector).forEach((tab, index) => {
              if (current === index) {
                tab.classList.add('active');
              } else {
                tab.classList.remove('active');
              }
            });
          },
        },
      }),
  });
};

export default mountVueTabs;
