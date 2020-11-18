import { nextTick } from 'vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton, GlAlert, GlLoadingIcon, GlTabs, GlTab } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import VueApollo from 'vue-apollo';
import createMockApollo from 'jest/helpers/mock_apollo_helper';

import { redirectTo, refreshCurrentPage, objectToQuery } from '~/lib/utils/url_utility';
import {
  mockProjectPath,
  mockDefaultBranch,
  mockCiConfigPath,
  mockCommitId,
  mockCiYml,
  mockNewMergeRequestPath,
  mockCommitMessage,
} from './mock_data';

import TextEditor from '~/pipeline_editor/components/text_editor.vue';
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import PipelineEditorApp from '~/pipeline_editor/pipeline_editor_app.vue';
import CommitForm from '~/pipeline_editor/components/commit/commit_form.vue';

const localVue = createLocalVue();
localVue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
  refreshCurrentPage: jest.fn(),
  objectToQuery: jest.requireActual('~/lib/utils/url_utility').objectToQuery,
  mergeUrlParams: jest.requireActual('~/lib/utils/url_utility').mergeUrlParams,
}));

describe('~/pipeline_editor/pipeline_editor_app.vue', () => {
  let wrapper;

  let mockMutate;
  let mockApollo;
  let mockBlobContentData;

  const createComponent = (
    { props = {}, loading = false, options = {} } = {},
    mountFn = shallowMount,
  ) => {
    mockMutate = jest.fn().mockResolvedValue({
      data: {
        commitCreate: {
          errors: [],
          commit: {},
        },
      },
    });

    wrapper = mountFn(PipelineEditorApp, {
      propsData: {
        projectPath: mockProjectPath,
        defaultBranch: mockDefaultBranch,
        ciConfigPath: mockCiConfigPath,
        newMergeRequestPath: mockNewMergeRequestPath,
        commitId: mockCommitId,
        ...props,
      },
      stubs: {
        GlTabs,
        GlButton,
        TextEditor,
        CommitForm,
      },
      mocks: {
        $apollo: {
          queries: {
            content: {
              loading,
            },
          },
          mutate: mockMutate,
        },
      },
      ...options,
    });
  };

  const createComponentWithApollo = ({ props = {} } = {}, mountFn = shallowMount) => {
    mockApollo = createMockApollo([], {
      Query: {
        blobContent() {
          return {
            __typename: 'BlobContent',
            rawData: mockBlobContentData(),
          };
        },
      },
    });

    const options = {
      localVue,
      mocks: {},
      apolloProvider: mockApollo,
    };

    createComponent({ props, options }, mountFn);
  };

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findAlert = () => wrapper.find(GlAlert);
  const findTabAt = i => wrapper.findAll(GlTab).at(i);
  const findEditorLite = () => wrapper.find(EditorLite);
  const findCommitForm = () => wrapper.find(CommitForm);
  const findCommitBtnLoadingIcon = () => wrapper.find('[type="submit"]').find(GlLoadingIcon);

  beforeEach(() => {
    mockBlobContentData = jest.fn();
  });

  afterEach(() => {
    mockBlobContentData.mockReset();
    refreshCurrentPage.mockReset();
    redirectTo.mockReset();
    mockMutate.mockReset();

    wrapper.destroy();
    wrapper = null;
  });

  it('displays a loading icon if the query is loading', () => {
    createComponent({ loading: true });

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findEditorLite().exists()).toBe(false);
  });

  describe('tabs', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays tabs and their content', async () => {
      expect(
        findTabAt(0)
          .find(EditorLite)
          .exists(),
      ).toBe(true);
      expect(
        findTabAt(1)
          .find(PipelineGraph)
          .exists(),
      ).toBe(true);
    });

    it('displays editor tab lazily, until editor is ready', async () => {
      expect(findTabAt(0).attributes('lazy')).toBe('true');

      findEditorLite().vm.$emit('editor-ready');

      await nextTick();

      expect(findTabAt(0).attributes('lazy')).toBe(undefined);
    });
  });

  describe('when data is set', () => {
    beforeEach(async () => {
      createComponent();

      wrapper.setData({
        content: mockCiYml,
        contentModel: mockCiYml,
      });

      await nextTick();
    });

    it('displays content after the query loads', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEditorLite().props('value')).toBe(mockCiYml);
    });

    describe('commit form', () => {
      const mockVariables = {
        projectPath: mockProjectPath,
        filePath: mockCiConfigPath,
        content: mockCiYml,
        startBranch: mockDefaultBranch,
        lastCommitId: mockCommitId,
        message: mockCommitMessage,
      };

      const emitSubmit = event => {
        findCommitForm().vm.$emit('submit', {
          message: mockCommitMessage,
          branch: mockDefaultBranch,
          openMergeRequest: false,
          ...event,
        });
      };

      describe('when the user commits changes to the current branch', () => {
        beforeEach(async () => {
          emitSubmit();
          await nextTick();
        });

        it('calls the mutation with the default branch', () => {
          expect(mockMutate).toHaveBeenCalledWith({
            mutation: expect.any(Object),
            variables: {
              ...mockVariables,
              branch: mockDefaultBranch,
            },
          });
        });

        it('refreshes the page', () => {
          expect(refreshCurrentPage).toHaveBeenCalledWith();
        });

        it('shows no saving state', () => {
          expect(findCommitBtnLoadingIcon().exists()).toBe(false);
        });
      });

      describe('when the user commits changes to a new branch', () => {
        const newBranch = 'new-branch';

        beforeEach(() => {
          emitSubmit({
            branch: newBranch,
          });
        });

        it('calls the mutation with the new branch', () => {
          expect(mockMutate).toHaveBeenCalledWith({
            mutation: expect.any(Object),
            variables: {
              ...mockVariables,
              branch: newBranch,
            },
          });
        });

        it('refreshes the page', () => {
          expect(refreshCurrentPage).toHaveBeenCalledWith();
        });
      });

      describe('when the user commits changes to open a new merge request', () => {
        const newBranch = 'new-branch';

        beforeEach(() => {
          emitSubmit({
            branch: newBranch,
            openMergeRequest: true,
          });
        });

        it('redirects to the merge request page with source and target branches', () => {
          const branchesQuery = objectToQuery({
            'merge_request[source_branch]': newBranch,
            'merge_request[target_branch]': mockDefaultBranch,
          });

          expect(redirectTo).toHaveBeenCalledWith(`${mockNewMergeRequestPath}?${branchesQuery}`);
        });
      });

      describe('when the commit is ocurring', () => {
        it('shows a saving state', async () => {
          await mockMutate.mockImplementationOnce(() => {
            expect(findCommitBtnLoadingIcon().exists()).toBe(true);
            return Promise.resolve();
          });

          findCommitForm().vm.$emit('submit', {
            message: mockCommitMessage,
            branch: mockDefaultBranch,
            openMergeRequest: false,
          });
        });
      });

      describe('when the commit fails', () => {
        it('shows a the error message', async () => {
          mockMutate.mockRejectedValueOnce(new Error('commit failed'));

          emitSubmit();

          await waitForPromises();

          expect(findAlert().text()).toBe('CI file could not be saved: commit failed');
        });

        it('shows an unkown error', async () => {
          mockMutate.mockRejectedValueOnce();

          emitSubmit();

          await waitForPromises();

          expect(findAlert().text()).toBe('CI file could not be saved: Unknown Error');
        });
      });

      describe('when the commit form is cancelled', () => {
        const otherContent = 'other content';

        beforeEach(async () => {
          findEditorLite().vm.$emit('input', otherContent);
          await nextTick();
        });

        it('content is restored after cancel is called', async () => {
          findCommitForm().vm.$emit('cancel');

          await nextTick();

          expect(findEditorLite().props('value')).toBe(mockCiYml);
        });
      });
    });
  });

  describe('displays fetch content errors', () => {
    it('no error is show when data is set', async () => {
      mockBlobContentData.mockResolvedValue(mockCiYml);
      createComponentWithApollo();

      await waitForPromises();

      expect(findAlert().exists()).toBe(false);
      expect(findEditorLite().props('value')).toBe(mockCiYml);
    });

    it('shows a 404 error message', async () => {
      mockBlobContentData.mockRejectedValueOnce({
        response: {
          data: {
            message: 'missing file!',
          },
        },
      });
      createComponentWithApollo();

      await waitForPromises();

      expect(findAlert().text()).toMatch('CI file could not be loaded: missing file!');
    });

    it('shows a 400 error message', async () => {
      mockBlobContentData.mockRejectedValueOnce({
        response: {
          data: {
            error: 'ref is missing',
          },
        },
      });
      createComponentWithApollo();

      await waitForPromises();

      expect(findAlert().text()).toMatch('CI file could not be loaded: ref is missing');
    });

    it('shows a unkown error message', async () => {
      mockBlobContentData.mockRejectedValueOnce('');
      createComponentWithApollo();
      await waitForPromises();

      expect(findAlert().text()).toMatch('CI file could not be loaded: Unknown Error');
    });
  });
});
