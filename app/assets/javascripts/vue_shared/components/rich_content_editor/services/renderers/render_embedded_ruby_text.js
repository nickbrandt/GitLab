import { renderDefaultBlock } from './render_utils';

const embeddedRubyRegex = /(^<%.+%>$)/;

const canRender = ({ literal }) => {
  return embeddedRubyRegex.test(literal);
};

const render = renderDefaultBlock;

export default { canRender, render };
