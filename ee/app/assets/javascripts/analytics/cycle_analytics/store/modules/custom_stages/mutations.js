import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

export default {
  [types.SET_STAGE_EVENTS](state, data = []) {
    state.formEvents = data.map(ev => convertObjectPropsToCamelCase(ev, { deep: true }));
  },
  [types.SHOW_CREATE_FORM](state) {
    state.isCreatingCustomStage = true;
    state.formInitialData = null;
    state.formErrors = null;
  },
  [types.SHOW_EDIT_FORM](state, initialData) {
    state.isEditingCustomStage = true;
    state.formInitialData = initialData;
    state.formErrors = null;
  },
  [types.HIDE_FORM](state) {
    state.isEditingCustomStage = false;
    state.isCreatingCustomStage = false;
    state.formInitialData = null;
    state.formErrors = null;
  },
  [types.CLEAR_FORM_ERRORS](state) {
    state.formErrors = null;
  },
  [types.REQUEST_CREATE_STAGE](state) {
    state.isSavingCustomStage = true;
    state.formErrors = {};
  },
  [types.RECEIVE_CREATE_STAGE_ERROR](state, { errors = null } = {}) {
    state.isSavingCustomStage = false;
    state.formErrors = convertObjectPropsToCamelCase(errors, { deep: true });
  },
  [types.RECEIVE_CREATE_STAGE_SUCCESS](state) {
    state.isSavingCustomStage = false;
    state.formErrors = null;
    state.formInitialData = null;
  },
};
