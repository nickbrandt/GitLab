import {
  buildTextToken,
  buildOpenToken,
  buildCloseToken,
  buildUneditableOpenToken,
} from './build_uneditable_token';

const embeddedRubyRegex = /(^<%.+%>$)/;

const isEmbeddedRuby = literal => {
  return embeddedRubyRegex.test(literal);
};

const canRender = (node, { entering, getChildrenText }) => {
  const childrenText = getChildrenText(node);
  return isEmbeddedRuby(childrenText) && entering;
};

const getChildrenTextWithIndentation = (parentNode, { options: { softbreak } }) => {
  const buffer = [];
  const walker = parentNode.walker();
  const { lineOffsets } = parentNode;
  let event = walker.next();
  let lineCount = 0;

  while (event) {
    const { node } = event;

    // TODO need to account for various inline types like anchor links
    if (node.type === 'text') {
      const indent = ' '.repeat(lineOffsets[lineCount]);
      const line = `${indent}${node.literal}`;
      buffer.push(line);
      lineCount += 1;
    }

    event = walker.next();
  }

  return buffer.join(softbreak);
};

const render = (node, context) => {
  // We skipChildren() as we want to process the rendering as a single plain text (preformatted code) unit
  context.skipChildren();

  const tokens = [
    buildUneditableOpenToken('pre', { attributes: { 'data-sse-erb': true } }),
    buildOpenToken('code'),
    buildTextToken(getChildrenTextWithIndentation(node, context)),
    buildCloseToken('code'),
    buildCloseToken('pre'),
  ];

  return tokens;
};

export default { canRender, render };
