import { merge } from 'lodash';

const TAG_TYPES = {
  block: 'div',
  inline: 'a',
};

const buildToken = (type, tagName, props) => {
  return { type, tagName, ...props };
};

const buildProps = (props = {}) => {
  const defaultProps = {
    attributes: { contenteditable: false },
    classNames: [
      'gl-px-4 gl-py-2 gl-my-5 gl-opacity-5 gl-bg-gray-100 gl-user-select-none gl-cursor-not-allowed',
    ],
  };

  return merge(defaultProps, props);
};

// Open helpers (singular and multiple)

export const buildOpenToken = tagType => buildToken('openTag', tagType);

export const buildCloseToken = tagType => buildToken('closeTag', tagType);

export const buildUneditableOpenToken = (tagType = TAG_TYPES.block, props) =>
  buildToken('openTag', tagType, buildProps(props));

export const buildUneditableOpenTokens = (token, tagType = TAG_TYPES.block) => {
  return [buildUneditableOpenToken(tagType), token];
};

// Close helpers (singular and multiple)

// TODO refactor by replacing uses of `buildUneditableCloseToken` with `buildCloseToken` as there is nothing technically about a close token being qualified as "uneditable"
export const buildUneditableCloseToken = (tagType = TAG_TYPES.block) => buildCloseToken(tagType);

export const buildUneditableCloseTokens = (token, tagType = TAG_TYPES.block) => {
  return [token, buildUneditableCloseToken(tagType)];
};

// Complete helpers (open plus close)

export const buildTextToken = content => buildToken('text', null, { content });

export const buildUneditableBlockTokens = token => {
  return [...buildUneditableOpenTokens(token), buildUneditableCloseToken()];
};

export const buildUneditableInlineTokens = token => {
  return [
    ...buildUneditableOpenTokens(token, TAG_TYPES.inline),
    buildUneditableCloseToken(TAG_TYPES.inline),
  ];
};

export const buildUneditableHtmlAsTextTokens = node => {
  /*
  Toast UI internally appends ' data-tomark-pass ' attribute flags so it can target certain
  nested nodes for internal use during Markdown <=> WYSIWYG conversions. In our case, we want
  to prevent HTML being rendered completely in WYSIWYG mode and thus we use a `text` vs. `html`
  type when building the token. However, in doing so, we need to strip out the ` data-tomark-pass `
  to prevent their persistence within the `text` content as the user did not intend these as edits.

  https://github.com/nhn/tui.editor/blob/cc54ec224fc3a4b6e5a2b19a71650959f41adc0e/apps/editor/src/js/convertor.js#L72
  */
  const regex = / data-tomark-pass /gm;
  const content = node.literal.replace(regex, '');
  const htmlAsTextToken = buildToken('text', null, { content });

  return [buildUneditableOpenToken(), htmlAsTextToken, buildUneditableCloseToken()];
};
