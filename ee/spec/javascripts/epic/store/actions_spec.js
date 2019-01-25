import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';

import defaultState from 'ee/epic/store/state';
import * as actions from 'ee/epic/store/actions';
import epicUtils from 'ee/epic/utils/epic_utils';
import { statusType } from 'ee/epic/constants';

import axios from '~/lib/utils/axios_utils';
import testAction from 'spec/helpers/vuex_action_helper';

import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('Epic Store Actions', () => {
  let state;

  beforeEach(() => {
    state = Object.assign({}, defaultState);
  });

  describe('setEpicMeta', () => {
    it('should set received Epic meta', done => {
      testAction(
        actions.setEpicMeta,
        mockEpicMeta,
        {},
        [{ type: 'SET_EPIC_META', payload: mockEpicMeta }],
        [],
        done,
      );
    });
  });

  describe('setEpicData', () => {
    it('should set received Epic data', done => {
      testAction(
        actions.setEpicData,
        mockEpicData,
        {},
        [{ type: 'SET_EPIC_DATA', payload: mockEpicData }],
        [],
        done,
      );
    });
  });

  describe('requestEpicStatusChange', () => {
    it('should set status change flag', done => {
      testAction(
        actions.requestEpicStatusChange,
        {},
        state,
        [{ type: 'REQUEST_EPIC_STATUS_CHANGE' }],
        [],
        done,
      );
    });
  });

  describe('requestEpicStatusChangeSuccess', () => {
    it('should set epic state type', done => {
      testAction(
        actions.requestEpicStatusChangeSuccess,
        { state: statusType.close },
        state,
        [{ type: 'REQUEST_EPIC_STATUS_CHANGE_SUCCESS', payload: { state: statusType.close } }],
        [],
        done,
      );
    });
  });

  describe('requestEpicStatusChangeFailure', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it('should set status change flag', done => {
      testAction(
        actions.requestEpicStatusChangeFailure,
        {},
        state,
        [{ type: 'REQUEST_EPIC_STATUS_CHANGE_FAILURE' }],
        [],
        done,
      );
    });

    it('should show flash error', done => {
      actions.requestEpicStatusChangeFailure({ commit: () => {} });

      Vue.nextTick()
        .then(() => {
          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            'Unable to update this epic at this time.',
          );
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('triggerIssuableEvent', () => {
    it('Calls `triggerDocumentEvent` with events `issuable_vue_app:change`, `issuable:change` and passes `isEpicOpen` as param', () => {
      spyOn(epicUtils, 'triggerDocumentEvent').and.returnValue(false);

      const data = { isEpicOpen: true };
      actions.triggerIssuableEvent({}, data);

      expect(epicUtils.triggerDocumentEvent).toHaveBeenCalledWith(
        'issuable_vue_app:change',
        data.isEpicOpen,
      );

      expect(epicUtils.triggerDocumentEvent).toHaveBeenCalledWith(
        'issuable:change',
        data.isEpicOpen,
      );
    });
  });

  describe('toggleEpicStatus', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestEpicStatusChange and requestEpicStatusChangeSuccess when request is complete', done => {
        mock.onPut(/(.*)/).replyOnce(200, {
          state: statusType.close,
        });

        testAction(
          actions.toggleEpicStatus,
          null,
          state,
          [],
          [
            {
              type: 'requestEpicStatusChange',
            },
            {
              type: 'requestEpicStatusChangeSuccess',
              payload: { state: statusType.close },
            },
            {
              type: 'triggerIssuableEvent',
              payload: { isEpicOpen: true },
            },
          ],
          done,
        );
      });
    });

    describe('failure', () => {
      it('dispatches requestEpicStatusChange and requestEpicStatusChangeFailure when request fails', done => {
        mock.onPut(/(.*)/).replyOnce(500, {});

        testAction(
          actions.toggleEpicStatus,
          null,
          state,
          [],
          [
            {
              type: 'requestEpicStatusChange',
            },
            {
              type: 'requestEpicStatusChangeFailure',
            },
            {
              type: 'triggerIssuableEvent',
              payload: { isEpicOpen: true },
            },
          ],
          done,
        );
      });
    });
  });

  describe('toggleSidebarFlag', () => {
    it('should call `TOGGLE_SIDEBAR` mutation with param `sidebarCollapsed`', done => {
      const sidebarCollapsed = true;

      testAction(
        actions.toggleSidebarFlag,
        sidebarCollapsed,
        state,
        [{ type: 'TOGGLE_SIDEBAR', payload: sidebarCollapsed }],
        [],
        done,
      );
    });
  });

  describe('toggleContainerClassAndCookie', () => {
    const sidebarCollapsed = true;

    beforeEach(() => {
      spyOn(epicUtils, 'toggleContainerClass').and.stub();
      spyOn(epicUtils, 'setCollapsedGutter').and.stub();
    });

    it('should call `epicUtils.toggleContainerClass` with classes `right-sidebar-expanded` & `right-sidebar-collapsed`', () => {
      actions.toggleContainerClassAndCookie({}, sidebarCollapsed);

      expect(epicUtils.toggleContainerClass).toHaveBeenCalledTimes(2);
      expect(epicUtils.toggleContainerClass).toHaveBeenCalledWith('right-sidebar-expanded');
      expect(epicUtils.toggleContainerClass).toHaveBeenCalledWith('right-sidebar-collapsed');
    });

    it('should call `epicUtils.setCollapsedGutter` with param `isSidebarCollapsed`', () => {
      actions.toggleContainerClassAndCookie({}, sidebarCollapsed);

      expect(epicUtils.setCollapsedGutter).toHaveBeenCalledWith(sidebarCollapsed);
    });
  });

  describe('toggleSidebar', () => {
    it('dispatches toggleContainerClassAndCookie and toggleSidebarFlag actions with opposite value of `isSidebarCollapsed` param', done => {
      const sidebarCollapsed = true;

      testAction(
        actions.toggleSidebar,
        { sidebarCollapsed },
        state,
        [],
        [
          {
            type: 'toggleContainerClassAndCookie',
            payload: !sidebarCollapsed,
          },
          {
            type: 'toggleSidebarFlag',
            payload: !sidebarCollapsed,
          },
        ],
        done,
      );
    });
  });
});
