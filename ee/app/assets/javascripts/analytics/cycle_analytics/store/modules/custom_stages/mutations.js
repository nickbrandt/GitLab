import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';
import { transformRawStages } from '../../../utils';

const extractFormFields = (rawStage = {}) => {
  const [
    {
      id = null,
      name = null,
      startEventIdentifier = null,
      startEventLabel: { id: startEventLabelId = null } = {},
      endEventIdentifier = null,
      endEventLabel: { id: endEventLabelId = null } = {},
    },
  ] = transformRawStages([rawStage]);
  return {
    id,
    name,
    startEventIdentifier,
    startEventLabelId,
    endEventIdentifier,
    endEventLabelId,
  };
};

export default {
  [types.SET_STAGE_EVENTS](state, data = []) {
    state.formEvents = data.map(ev => convertObjectPropsToCamelCase(ev, { deep: true }));
  },
  [types.SET_STAGE_FORM_ERRORS](state, errors) {
    state.isSavingCustomStage = false;
    state.formErrors = convertObjectPropsToCamelCase(errors, { deep: true });
  },
  [types.SET_FORM_INITIAL_DATA](state, rawStageData = null) {
    state.formInitialData = extractFormFields(rawStageData);
  },
  [types.SHOW_CREATE_FORM](state) {
    state.isEditingCustomStage = false;
    state.isCreatingCustomStage = true;
    state.formInitialData = null;
    state.formErrors = null;
  },
  [types.SHOW_EDIT_FORM](state) {
    state.isCreatingCustomStage = false;
    state.isEditingCustomStage = true;
    state.formErrors = null;
  },
  [types.HIDE_FORM](state) {
    state.isSavingCustomStage = false;
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
  [types.RECEIVE_CREATE_STAGE_ERROR](state) {
    state.isSavingCustomStage = false;
  },
  [types.RECEIVE_CREATE_STAGE_SUCCESS](state) {
    state.isSavingCustomStage = false;
    state.formErrors = null;
    state.formInitialData = null;
  },
};
