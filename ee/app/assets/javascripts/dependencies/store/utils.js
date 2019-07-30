import listModule from './modules/list';

// eslint-disable-next-line import/prefer-default-export
export const addListType = (store, listType) => {
  const { initialState, namespace } = listType;
  store.registerModule(namespace, listModule());
  store.dispatch('addListType', listType);
  store.dispatch(`${namespace}/setInitialState`, initialState);
};
