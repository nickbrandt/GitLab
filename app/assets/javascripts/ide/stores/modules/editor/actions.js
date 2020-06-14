/* eslint-disable import/prefer-default-export */
import * as types from './mutation_types';

export const setFileInfo = ({ commit }, payload) => {
  commit(types.SET_FILE_INFO, payload);
};
