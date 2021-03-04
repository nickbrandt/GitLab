import { GlAlert, GlButton, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';

import DeleteModal from 'ee/groups/settings/compliance_frameworks/components/delete_modal.vue';
import List from 'ee/groups/settings/compliance_frameworks/components/list.vue';
import EmptyState from 'ee/groups/settings/compliance_frameworks/components/list_empty_state.vue';
import ListItem from 'ee/groups/settings/compliance_frameworks/components/list_item.vue';
import { PIPELINE_CONFIGURATION_PATH_FORMAT } from 'ee/groups/settings/compliance_frameworks/constants';
import getComplianceFrameworkQuery from 'ee/groups/settings/compliance_frameworks/graphql/queries/get_compliance_framework.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { validFetchResponse, emptyFetchResponse } from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('List', () => {
  let wrapper;
  const sentryError = new Error('Network error');

  const fetch = jest.fn().mockResolvedValue(validFetchResponse);
  const fetchEmpty = jest.fn().mockResolvedValue(emptyFetchResponse);
  const fetchLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const fetchWithErrors = jest.fn().mockRejectedValue(sentryError);

  const findAlert = () => wrapper.find(GlAlert);
  const findDeleteModal = () => wrapper.findComponent(DeleteModal);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findEmptyState = () => wrapper.find(EmptyState);
  const findTabs = () => wrapper.findAll(GlTab);
  const findAddBtn = () => wrapper.find(GlButton);
  const findTabsContainer = () => wrapper.find(GlTabs);
  const findListItems = () => wrapper.findAll(ListItem);

  function createMockApolloProvider(resolverMock) {
    localVue.use(VueApollo);

    const requestHandlers = [[getComplianceFrameworkQuery, resolverMock]];

    return createMockApollo(requestHandlers);
  }

  function createComponentWithApollo(resolverMock) {
    return shallowMount(List, {
      localVue,
      apolloProvider: createMockApolloProvider(resolverMock),
      propsData: {
        addFrameworkPath: 'group/framework/new',
        emptyStateSvgPath: 'dir/image.svg',
        groupPath: 'group-1',
      },
      stubs: {
        GlLoadingIcon,
        GlTab,
        GlTabs,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading', () => {
    beforeEach(() => {
      wrapper = createComponentWithApollo(fetchLoading);
    });

    it('shows the loader', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show the other parts of the app', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findTabsContainer().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('fetching error', () => {
    beforeEach(() => {
      wrapper = createComponentWithApollo(fetchWithErrors);
    });

    it('shows the alert', () => {
      expect(findAlert().props('dismissible')).toBe(false);
      expect(findAlert().props('variant')).toBe('danger');
      expect(findAlert().text()).toBe(
        'Error fetching compliance frameworks data. Please refresh the page',
      );
    });

    it('does not show the other parts of the app', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTabsContainer().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('should fetch data once', () => {
      expect(fetchWithErrors).toHaveBeenCalledTimes(1);
    });

    it('sends the error to Sentry', async () => {
      jest.spyOn(Sentry, 'captureException');

      await waitForPromises();

      expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(sentryError);
    });
  });

  describe('empty state', () => {
    beforeEach(() => {
      wrapper = createComponentWithApollo(fetchEmpty);
    });

    it('shows the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('imagePath')).toBe('dir/image.svg');
      expect(findEmptyState().props('addFrameworkPath')).toBe('group/framework/new');
    });

    it('does not show the other parts of the app', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTabsContainer().exists()).toBe(false);
      expect(findDeleteModal().exists()).toBe(false);
    });
  });

  describe('content', () => {
    beforeEach(() => {
      wrapper = createComponentWithApollo(fetch);
    });

    it('does not show the other parts of the app', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
    });

    it('shows the tabs', () => {
      expect(findTabsContainer().exists()).toBe(true);
      expect(findTabs()).toHaveLength(2);
    });

    it('shows the all tab', () => {
      expect(findTabs().at(0).attributes('title')).toBe('All');
    });

    it('shows the disabled regulated tab', () => {
      const tab = findTabs().at(1);

      expect(tab.attributes('title')).toBe('Regulated');
      expect(tab.attributes('disabled')).toBe('true');
    });

    it('shows the add framework button', () => {
      const addBtn = findAddBtn();

      expect(addBtn.attributes('href')).toBe('group/framework/new');
      expect(addBtn.text()).toBe('Add framework');
    });

    it('shows the list items with expect props', () => {
      expect(findListItems()).toHaveLength(2);

      findListItems().wrappers.forEach((item) =>
        expect(item.props()).toEqual(
          expect.objectContaining({
            framework: {
              id: expect.stringContaining('gid://gitlab/ComplianceManagement::Framework/'),
              parsedId: expect.any(Number),
              name: expect.any(String),
              description: expect.any(String),
              pipelineConfigurationFullPath: expect.stringMatching(
                PIPELINE_CONFIGURATION_PATH_FORMAT,
              ),
              color: expect.stringMatching(/^#([0-9A-F]{3}){1,2}$/i),
            },
            loading: false,
          }),
        ),
      );
    });

    it('renders the delete modal', () => {
      expect(findDeleteModal().exists()).toBe(true);
    });
  });

  describe('delete framework', () => {
    describe('when an item is marked for deletion', () => {
      let framework;
      const findListItem = () => findListItems().at(0);

      beforeEach(async () => {
        wrapper = createComponentWithApollo(fetch);

        await waitForPromises();

        framework = findListItem().props('framework');
        findDeleteModal().vm.show = jest.fn();
        findListItem().vm.$emit('delete', framework);
      });

      it('shows the modal when there is a "delete" event from a list item', () => {
        expect(findDeleteModal().props('id')).toBe(framework.id);
        expect(findDeleteModal().props('name')).toBe(framework.name);
        expect(findDeleteModal().vm.show).toHaveBeenCalled();
      });

      describe('and multiple items are being deleted', () => {
        beforeEach(() => {
          findListItems().wrappers.forEach((listItem) => {
            listItem.vm.$emit('delete', listItem.props('framework'));
            findDeleteModal().vm.$emit('deleting');
          });
        });

        it('sets "loading" to true on the deleting list items', () => {
          expect(findListItems().wrappers.every((listItem) => listItem.props('loading'))).toBe(
            true,
          );
        });

        describe('and an error occurred', () => {
          beforeEach(() => {
            findDeleteModal().vm.$emit('error');
          });

          it('shows the alert for the error', () => {
            expect(findAlert().props('dismissible')).toBe(false);
            expect(findAlert().props('variant')).toBe('danger');
            expect(findAlert().text()).toBe(
              'Error deleting the compliance framework. Please try again',
            );
          });
        });

        describe('and the item was successfully deleted', () => {
          beforeEach(async () => {
            findDeleteModal().vm.$emit('delete', framework.id);
            await waitForPromises();
          });

          it('sets "loading" to false on the deleted list item', () => {
            expect(findListItem().props('loading')).toBe(false);
          });

          it('shows the alert for the success message', () => {
            expect(findAlert().props('dismissible')).toBe(true);
            expect(findAlert().props('variant')).toBe('info');
            expect(findAlert().text()).toBe('Compliance framework deleted successfully');
          });
        });
      });
    });
  });
});
