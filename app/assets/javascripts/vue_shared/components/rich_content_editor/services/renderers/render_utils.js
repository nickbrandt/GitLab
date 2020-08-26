import {
  buildUneditableBlockTokens,
  buildUneditableOpenTokens,
  buildUneditableCloseToken,
} from './build_uneditable_token';

const attributeDefinitionRegexp = /(^{:.+}$)/;

export const renderUneditableLeaf = (_, { origin }) => buildUneditableBlockTokens(origin());

export const renderUneditableBranch = (_, { entering, origin }) =>
  entering ? buildUneditableOpenTokens(origin()) : buildUneditableCloseToken();

export const isAttributeDefinition = text => attributeDefinitionRegexp.test(text);

const findAttributeDefinition = node => {
  const literal =
    node?.next?.firstChild?.literal || node?.firstChild?.firstChild?.next?.next?.literal; // for headings // for list items;

  return isAttributeDefinition(literal) ? literal : null;
};

export const renderWithAttributeDefinitions = (node, context) => {
  const attributes = findAttributeDefinition(node);
  const origin = context.origin();

  if (origin.type === 'openTag' && attributes) {
    Object.assign(origin, {
      attributes: {
        'data-attribute-definition': attributes,
        'data-toggle': 'tooltip',
        'data-placement': 'left',
        title: attributes,
      },
    });
  }

  return origin;
};

export const canRender = () => true;
