// eslint-disable-next-line import/prefer-default-export
export const formHasError = state => Object.values(state.formErrors).some(val => Boolean(val));
