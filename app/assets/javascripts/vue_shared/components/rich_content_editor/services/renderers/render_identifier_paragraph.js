import { renderEnterExitBlock } from './render_utils';

const identifierRegex = /(^\[.+\]: .+)/;

const isIdentifier = text => {
  return identifierRegex.test(text);
};

const canRender = (node, context) => {
  return isIdentifier(context.getChildrenText(node));
};

const render = renderEnterExitBlock;

export default { canRender, render };
