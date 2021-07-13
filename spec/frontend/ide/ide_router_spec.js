import waitForPromises from 'helpers/wait_for_promises';
import { createRouter } from '~/ide/ide_router';
import { createStore } from '~/ide/stores';

describe('IDE router', () => {
  const PROJECT_NAMESPACE = 'my-group/sub-group';
  const PROJECT_NAME = 'my-project';
  const DEFAULT_BRANCH_ID = 'main';
  const TEST_PATH = `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/merge_requests/2`;
  const PSEUDO_MR_PATH = `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/${DEFAULT_BRANCH_ID}/-/src/merge_requests/2`;

  let store;
  let router;

  beforeEach(() => {
    window.history.replaceState({}, '', '/');
    store = createStore();
    router = createRouter(store);
    jest.spyOn(store, 'dispatch').mockReturnValue(new Promise(() => {}));
  });

  it.each`
    route                                                                                     | branchId                   | basePath
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/${DEFAULT_BRANCH_ID}/-/src/blob/`}  | ${DEFAULT_BRANCH_ID}       | ${'src/blob/'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/${DEFAULT_BRANCH_ID}/-/src/blob`}   | ${DEFAULT_BRANCH_ID}       | ${'src/blob'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/blob/-/src/blob`}                   | ${undefined}               | ${'src/blob'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/${DEFAULT_BRANCH_ID}/-/src/tree/`}  | ${DEFAULT_BRANCH_ID}       | ${'src/tree/'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/weird:branch/name-123/-/src/tree/`} | ${'weird:branch/name-123'} | ${'src/tree/'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/${DEFAULT_BRANCH_ID}/-/src/blob`}   | ${DEFAULT_BRANCH_ID}       | ${'src/blob'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/${DEFAULT_BRANCH_ID}/-/src/edit`}   | ${DEFAULT_BRANCH_ID}       | ${'src/edit'}
    ${PSEUDO_MR_PATH}                                                                         | ${DEFAULT_BRANCH_ID}       | ${'src/merge_requests/2'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/blob/-/src/blob`}                   | ${undefined}               | ${'src/blob'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/edit/blob/-/src/blob`}                   | ${undefined}               | ${'src/blob'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/blob`}                              | ${undefined}               | ${undefined}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/edit`}                                   | ${undefined}               | ${undefined}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}`}                                        | ${undefined}               | ${''}
  `('opens correct branch if supplied when route is "$route"', ({ route, branchId, basePath }) => {
    router.push(route);

    if (branchId) {
      expect(store.dispatch).toHaveBeenCalledWith('openBranch', {
        projectId: `${PROJECT_NAMESPACE}/${PROJECT_NAME}`,
        branchId,
        basePath,
      });
    }
    expect(store.dispatch).not.toHaveBeenCalledWith('openMergeRequest');
  });

  it.each`
    route                                                                 | mrId
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/merge_requests/2`}   | ${'2'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/merge_requests/`}    | ${undefined}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/merge_requests`}     | ${undefined}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/merge_requests/2/3`} | ${'2/3'}
  `('opens MR for "$route"', ({ route, branchId, basePath }) => {
    router.push(route);

    if (branchId) {
      expect(store.dispatch).toHaveBeenCalledWith('openMergeRequest', {
        projectId: `${PROJECT_NAMESPACE}/${PROJECT_NAME}`,
        mergeRequestId,
        targetProjectId: jest.any(),
      });
    }
    expect(store.dispatch).not.toHaveBeenCalledWith('openBranch');
  });

  it('keeps router in sync when store changes', async () => {
    expect(router.currentRoute.fullPath).toBe('/');

    store.state.router.fullPath = TEST_PATH;

    await waitForPromises();

    expect(router.currentRoute.fullPath).toBe(TEST_PATH);
  });

  it('keeps store in sync when router changes', () => {
    expect(store.dispatch).not.toHaveBeenCalled();

    router.push(TEST_PATH);

    expect(store.dispatch).toHaveBeenCalledWith('router/push', TEST_PATH, { root: true });
  });
});
