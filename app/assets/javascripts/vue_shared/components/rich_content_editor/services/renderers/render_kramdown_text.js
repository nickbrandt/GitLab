import { renderDefaultBlock } from './render_utils';

const kramdownRegex = /(^{:.+}$)/;

const canRender = ({ literal }) => {
  return kramdownRegex.test(literal);
};

const render = renderDefaultBlock;

export default { canRender, render };
