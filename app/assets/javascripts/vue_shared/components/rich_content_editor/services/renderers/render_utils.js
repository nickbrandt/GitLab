import {
  buildUneditableTokens,
  buildUneditableOpenTokens,
  buildUneditableCloseToken,
} from './build_uneditable_token';

export const renderDefaultBlock = (_, { origin }) => buildUneditableTokens(origin());

export const renderEnterExitBlock = (_, { entering, origin }) =>
  entering ? buildUneditableOpenTokens(origin()) : buildUneditableCloseToken();
