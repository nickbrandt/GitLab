import { buildUneditableHtmlTokens } from './build_uneditable_token';

const canRender = ({ type }) => {
  return type === 'htmlBlock';
};

const render = node => buildUneditableHtmlTokens(node);

export default { canRender, render };
