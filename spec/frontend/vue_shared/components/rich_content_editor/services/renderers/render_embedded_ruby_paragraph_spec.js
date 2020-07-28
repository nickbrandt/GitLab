import renderer from '~/vue_shared/components/rich_content_editor/services/renderers/render_embedded_ruby_paragraph';

import { buildMockTextNode } from './mock_data';

const normalParagraphNode = {
  firstChild: buildMockTextNode('This is just normal paragraph. It has multiple sentences.'),
  type: 'paragraph',
};

const erbParagraphLines = [
  '<% if apptype.maturity && (apptype.maturity != "planned") %>',
  '  <% maturity = "This application type is at the x level of maturity." %>',
  '<% end %>',
];

const singleLineErbParagraphNode = {
  firstChild: {
    firstChild: null,
    literal: erbParagraphLines[0],
    type: 'text',
  },
  type: 'paragraph',
};

const multiLineErbParagraphNode = {
  firstChild: {
    ...singleLineErbParagraphNode.firstChild,
    next: {
      type: 'softbreak',
      next: {
        firstChild: null,
        literal: erbParagraphLines[1],
        type: 'text',
        next: {
          type: 'softbreak',
          next: {
            firstChild: null,
            literal: erbParagraphLines[2],
            type: 'text',
          },
        },
      },
    },
  },
  type: 'paragraph',
};

describe('Render Embedded Ruby Paragraph renderer', () => {
  describe('canRender', () => {
    it.each`
      node                          | paragraph                                        | target
      ${singleLineErbParagraphNode} | ${singleLineErbParagraphNode.firstChild.literal} | ${true}
      ${multiLineErbParagraphNode}  | ${erbParagraphLines.join(' ')}                   | ${true}
      ${normalParagraphNode}        | ${normalParagraphNode.firstChild.literal}        | ${false}
    `('should return $target when the $node matches $paragraph', ({ node, paragraph, target }) => {
      const context = {
        entering: true,
        getChildrenText: jest.fn().mockReturnValueOnce(paragraph),
      };

      expect(renderer.canRender(node, context)).toBe(target);
    });
  });

  // describe('render', () => {
  //   it.each`
  //     node
  //     ${normalParagraphNode}
  //     ${singleLineErbParagraphNode}
  //     ${multiLineErbParagraphNode}
  //   `(
  //     'should return uneditable pre code tokens wrapping the $node childrenText as a text token',
  //     ({ node }) => {
  //       expect(renderer.render(node)).toStrictEqual(buildUneditableParagraphAsPreTokens(node));
  //     },
  //   );
  // });
});
