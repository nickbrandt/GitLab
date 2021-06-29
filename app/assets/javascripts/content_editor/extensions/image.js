import { nodeInputRule } from '@tiptap/core';
import { Image } from '@tiptap/extension-image';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { Plugin, PluginKey } from 'prosemirror-state';
import ImageWrapper from '../components/wrappers/image.vue';
import { uploadFile } from '../services/upload_file';
import { readFileAsDataURL } from '../services/utils';

export const imageSyntaxInputRuleRegExp = /(?:^|\s)!\[(?<alt>[\w|\s|-]+)\]\((?<src>.+?)\)$/gm;

const acceptedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/jpg'];

const startFileUpload = async ({ editor, file, uploadsPath, renderMarkdown }) => {
  const encodedSrc = await readFileAsDataURL(file);
  const { view } = editor;

  editor.commands.setImage({ uploading: true, encodedSrc });

  const { state } = view;
  const position = state.selection.from - 1;
  const { tr } = state;
  const { src, canonicalSrc } = await uploadFile({ file, uploadsPath, renderMarkdown });

  view.dispatch(
    tr.setNodeMarkup(position, undefined, {
      uploading: false,
      encodedSrc,
      src,
      canonicalSrc,
    }),
  );
};

const handleFileEvent = ({ editor, files, uploadsPath, renderMarkdown }) => {
  const file = files[0];

  if (acceptedMimes.includes(file?.type)) {
    startFileUpload({ editor, file, uploadsPath, renderMarkdown });

    return true;
  }

  return false;
};

export const ExtendedImage = Image.extend({
  defaultOptions: {
    ...Image.options,
    uploadsPath: null,
    renderMarkdown: null,
  },
  addInputRules() {
    return [nodeInputRule(imageSyntaxInputRuleRegExp, this.type, ({ groups }) => groups)];
  },
  addAttributes() {
    return {
      ...this.parent?.(),
      uploading: {
        default: false,
      },
      encodedSrc: {
        default: null,
      },
      src: {
        default: null,
        /*
         * GitLab Flavored Markdown provides lazy loading for rendering images. As
         * as result, the src attribute of the image may contain an embedded resource
         * instead of the actual image URL. The image URL is moved to the data-src
         * attribute.
         */
        parseHTML: (element) => {
          const img = element.querySelector('img');

          return {
            src: img.dataset.src,
          };
        },
      },
      canonicalSrc: {
        default: null,
        parseHTML: (element) => {
          return {
            canonicalSrc: element.dataset.canonicalSrc,
          };
        },
      },
      alt: {
        default: null,
        parseHTML: (element) => {
          const img = element.querySelector('img');

          return {
            alt: img.getAttribute('alt'),
          };
        },
      },
    };
  },
  parseHTML() {
    return [
      {
        priority: 100,
        tag: 'a.no-attachment-icon',
      },
      {
        tag: 'img[src]',
      },
    ];
  },
  addCommands() {
    return {
      ...this.parent(),
      uploadImage: ({ file }) => () => {
        const { uploadsPath, renderMarkdown } = this.options;

        startFileUpload({ file, uploadsPath, renderMarkdown, editor: this.editor });
      },
    };
  },
  addProseMirrorPlugins() {
    const { editor } = this;

    return [
      new Plugin({
        key: new PluginKey('handleDropAndPasteImages'),
        props: {
          handlePaste: (_, event) => {
            const { uploadsPath, renderMarkdown } = this.options;

            return handleFileEvent({
              editor,
              files: event.clipboardData.files,
              uploadsPath,
              renderMarkdown,
            });
          },
          handleDrop: (_, event) => {
            const { uploadsPath, renderMarkdown } = this.options;

            return handleFileEvent({
              editor,
              files: event.dataTransfer.files,
              uploadsPath,
              renderMarkdown,
            });
          },
        },
      }),
    ];
  },
  addNodeView() {
    return VueNodeViewRenderer(ImageWrapper);
  },
}).configure({ inline: true });

export const serializer = (state, node) => {
  const { alt = '', canonicalSrc, src, title } = node.attrs;
  const quotedTitle = title ? ` ${state.quote(title)}` : '';

  state.write(`![${state.esc(alt)}](${state.esc(canonicalSrc || src)}${quotedTitle})`);
};

export const configure = (config) => ({
  tiptapExtension: ExtendedImage.configure({
    ...config,
  }),
  serializer,
});
