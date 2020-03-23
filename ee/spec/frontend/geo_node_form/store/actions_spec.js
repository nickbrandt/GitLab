import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import flash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import * as actions from 'ee/geo_node_form/store/actions';
import * as types from 'ee/geo_node_form/store/mutation_types';
import createState from 'ee/geo_node_form/store/state';
import { MOCK_SYNC_NAMESPACES, MOCK_NODE } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  joinPaths: jest.fn(),
}));

describe('GeoNodeForm Store Actions', () => {
  let state;
  let mock;

  const noCallback = () => {};
  const flashCallback = () => {
    expect(flash).toHaveBeenCalledTimes(1);
    flash.mockClear();
  };
  const visitUrlCallback = () => {
    expect(visitUrl).toHaveBeenCalledWith('/admin/geo/nodes');
  };

  beforeEach(() => {
    state = createState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe.each`
    action                                  | data                    | mutationName                             | mutationCall                                                                      | callback
    ${actions.requestSyncNamespaces}        | ${null}                 | ${types.REQUEST_SYNC_NAMESPACES}         | ${{ type: types.REQUEST_SYNC_NAMESPACES }}                                        | ${noCallback}
    ${actions.receiveSyncNamespacesSuccess} | ${MOCK_SYNC_NAMESPACES} | ${types.RECEIVE_SYNC_NAMESPACES_SUCCESS} | ${{ type: types.RECEIVE_SYNC_NAMESPACES_SUCCESS, payload: MOCK_SYNC_NAMESPACES }} | ${noCallback}
    ${actions.receiveSyncNamespacesError}   | ${null}                 | ${types.RECEIVE_SYNC_NAMESPACES_ERROR}   | ${{ type: types.RECEIVE_SYNC_NAMESPACES_ERROR }}                                  | ${flashCallback}
    ${actions.requestSaveGeoNode}           | ${null}                 | ${types.REQUEST_SAVE_GEO_NODE}           | ${{ type: types.REQUEST_SAVE_GEO_NODE }}                                          | ${noCallback}
    ${actions.receiveSaveGeoNodeSuccess}    | ${null}                 | ${types.RECEIVE_SAVE_GEO_NODE_COMPLETE}  | ${{ type: types.RECEIVE_SAVE_GEO_NODE_COMPLETE }}                                 | ${visitUrlCallback}
    ${actions.receiveSaveGeoNodeError}      | ${null}                 | ${types.RECEIVE_SAVE_GEO_NODE_COMPLETE}  | ${{ type: types.RECEIVE_SAVE_GEO_NODE_COMPLETE }}                                 | ${flashCallback}
  `(`non-axios calls`, ({ action, data, mutationName, mutationCall, callback }) => {
    describe(action.name, () => {
      it(`should commit mutation ${mutationName}`, () => {
        testAction(action, data, state, [mutationCall], [], callback);
      });
    });
  });

  describe.each`
    action                         | axiosMock                                                           | data                          | type         | actionCalls
    ${actions.fetchSyncNamespaces} | ${{ method: 'onGet', code: 200, res: MOCK_SYNC_NAMESPACES }}        | ${null}                       | ${'success'} | ${[{ type: 'requestSyncNamespaces' }, { type: 'receiveSyncNamespacesSuccess', payload: MOCK_SYNC_NAMESPACES }]}
    ${actions.fetchSyncNamespaces} | ${{ method: 'onGet', code: 500, res: null }}                        | ${null}                       | ${'error'}   | ${[{ type: 'requestSyncNamespaces' }, { type: 'receiveSyncNamespacesError' }]}
    ${actions.saveGeoNode}         | ${{ method: 'onPost', code: 200, res: { ...MOCK_NODE, id: null } }} | ${{ ...MOCK_NODE, id: null }} | ${'success'} | ${[{ type: 'requestSaveGeoNode' }, { type: 'receiveSaveGeoNodeSuccess' }]}
    ${actions.saveGeoNode}         | ${{ method: 'onPost', code: 500, res: null }}                       | ${{ ...MOCK_NODE, id: null }} | ${'error'}   | ${[{ type: 'requestSaveGeoNode' }, { type: 'receiveSaveGeoNodeError' }]}
    ${actions.saveGeoNode}         | ${{ method: 'onPut', code: 200, res: MOCK_NODE }}                   | ${MOCK_NODE}                  | ${'success'} | ${[{ type: 'requestSaveGeoNode' }, { type: 'receiveSaveGeoNodeSuccess' }]}
    ${actions.saveGeoNode}         | ${{ method: 'onPut', code: 500, res: null }}                        | ${MOCK_NODE}                  | ${'error'}   | ${[{ type: 'requestSaveGeoNode' }, { type: 'receiveSaveGeoNodeError' }]}
  `(`axios calls`, ({ action, axiosMock, data, type, actionCalls }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          mock[axiosMock.method]().replyOnce(axiosMock.code, axiosMock.res);
        });
        it(`should dispatch the correct request and actions`, done => {
          testAction(action, data, state, [], actionCalls, done);
        });
      });
    });
  });
});
