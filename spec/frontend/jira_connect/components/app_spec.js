import { shallowMount } from '@vue/test-utils';

import JiraConnectApp from '~/jira_connect/components/app.vue';

describe('JiraConnectApp', () => {
  let wrapper;

  const createComponent = ({ ...options }) => {
    wrapper = shallowMount(JiraConnectApp, {
      ...options,
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findHeader = () => wrapper.find('h3');
  const findHeaderText = () => wrapper.find('h3').text();

  describe('template', () => {
    describe('newJiraConnectUi is false', () => {
      it('does not render new UI', () => {
        createComponent({
          provide: {
            glFeatures: { newJiraConnectUi: false },
          },
        });

        expect(findHeader().exists()).toBe(false);
      });
    });

    describe('newJiraConnectUi is true', () => {
      it('renders new UI', () => {
        createComponent({
          provide: {
            glFeatures: { newJiraConnectUi: true },
          },
        });

        expect(findHeader().exists()).toBe(true);
        expect(findHeaderText()).toBe('Linked namespaces');
      });
    });
  });
});
