import Document from '@tiptap/extension-document';
import Dropcursor from '@tiptap/extension-dropcursor';
import Gapcursor from '@tiptap/extension-gapcursor';
import { Editor } from '@tiptap/vue-2';
import { isFunction } from 'lodash';
import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '../constants';
import * as Blockquote from '../extensions/blockquote';
import * as Bold from '../extensions/bold';
import * as BulletList from '../extensions/bullet_list';
import * as Code from '../extensions/code';
import * as CodeBlockHighlight from '../extensions/code_block_highlight';
import * as HardBreak from '../extensions/hard_break';
import * as Heading from '../extensions/heading';
import * as HorizontalRule from '../extensions/horizontal_rule';
import * as Image from '../extensions/image';
import * as Italic from '../extensions/italic';
import * as Link from '../extensions/link';
import * as ListItem from '../extensions/list_item';
import * as OrderedList from '../extensions/ordered_list';
import * as Paragraph from '../extensions/paragraph';
import * as Text from '../extensions/text';
import { ContentEditor } from './content_editor';
import createMarkdownSerializer from './markdown_serializer';

const builtInContentEditorExtensions = [
  Blockquote,
  Bold,
  BulletList,
  Code,
  CodeBlockHighlight,
  BulletList,
  HardBreak,
  Heading,
  HorizontalRule,
  Italic,
  Image,
  Link,
  ListItem,
  OrderedList,
  Paragraph,
  Text,
];

const collectTiptapExtensions = (extensions = []) =>
  extensions.map(({ tiptapExtension }) => tiptapExtension);

const buildSerializerSpec = (extensions = []) =>
  extensions
    .filter(({ serializer }) => serializer)
    .reduce(
      (serializers, { serializer, tiptapExtension: { name, type } }) => {
        const collection = `${type}s`;

        return {
          ...serializers,
          [collection]: {
            ...serializers[collection],
            [name]: serializer,
          },
        };
      },
      {
        nodes: {},
        marks: {},
      },
    );

const createTiptapEditor = ({ extensions = [], ...options } = {}) =>
  new Editor({
    extensions: [Dropcursor, Gapcursor, History, Document, ...extensions],
    editorProps: {
      attributes: {
        class: 'gl-outline-0!',
      },
    },
    ...options,
  });

export const createContentEditor = ({ renderMarkdown, extensions = [], tiptapOptions } = {}) => {
  if (!isFunction(renderMarkdown)) {
    throw new Error(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
  }

  const allExtensions = [...builtInContentEditorExtensions, ...extensions];
  const tiptapExtensions = collectTiptapExtensions(allExtensions);
  const tiptapEditor = createTiptapEditor({ extensions: tiptapExtensions, ...tiptapOptions });
  const serializerSpec = buildSerializerSpec(allExtensions);
  const serializer = createMarkdownSerializer({ render: renderMarkdown, serializerSpec });

  return new ContentEditor({ tiptapEditor, serializer });
};
