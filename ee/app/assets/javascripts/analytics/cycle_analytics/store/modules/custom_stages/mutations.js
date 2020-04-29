import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

export default {
  [types.SET_STAGE_EVENTS](state, data = []) {
    state.formEvents = data.map(ev => convertObjectPropsToCamelCase(ev, { deep: true }));
  },
  [types.SHOW_CUSTOM_STAGE_FORM](state) {
    state.isCreating = true;
    state.formInitialData = null;
    state.formErrors = null;
  },
  [types.SHOW_EDIT_CUSTOM_STAGE_FORM](state, initialData) {
    state.isEditing = true;
    state.formInitialData = initialData;
    state.formErrors = null;
  },
  [types.HIDE_CUSTOM_STAGE_FORM](state) {
    state.isEditing = false;
    state.isCreating = false;
    state.formInitialData = null;
    state.formErrors = null;
  },
  [types.CLEAR_CUSTOM_STAGE_FORM_ERRORS](state) {
    state.formErrors = null;
  },
  [types.REQUEST_CREATE_CUSTOM_STAGE](state) {
    state.isSaving = true;
    state.formErrors = {};
  },
  [types.RECEIVE_CREATE_CUSTOM_STAGE_ERROR](state, { errors = null } = {}) {
    state.isSaving = false;
    state.formErrors = convertObjectPropsToCamelCase(errors, { deep: true });
  },
  [types.RECEIVE_CREATE_CUSTOM_STAGE_SUCCESS](state) {
    state.isSaving = false;
    state.formErrors = null;
    state.formInitialData = null;
  },
};
