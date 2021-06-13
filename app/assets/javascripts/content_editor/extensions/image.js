import { nodeInputRule } from '@tiptap/core';
import { Image } from '@tiptap/extension-image';
import { Plugin, PluginKey } from 'prosemirror-state';
import { uploadFile } from '../services/upload_file';

export const imageSyntaxInputRuleRegExp = /(?:^|\s)!\[(?<alt>[\w|\s|-]+)\]\((?<src>.+?)\)$/gm;

const acceptedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/jpg'];

const startFileUpload = async ({ file, uploadsPath, renderMarkdown, editor }) => {
  editor.emit('imageUploadStart');

  try {
    const data = await uploadFile({ file, uploadsPath, renderMarkdown });
    const { src, canonicalSrc } = data;

    editor.commands.setImage({ src, canonicalSrc, alt: '' });
    editor.emit('imageUploadSucceed', data);
  } catch (e) {
    editor.emit('imageUploadFailed');
  }
};

const handleFileEvent = ({ files, uploadsPath, renderMarkdown, editor }) => {
  const file = files[0];

  if (acceptedMimes.includes(file?.type)) {
    startFileUpload({ file, uploadsPath, renderMarkdown, editor });

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
    const extension = this;

    return [
      new Plugin({
        key: new PluginKey('handleDropAndPasteImages'),
        props: {
          handlePaste: (_, event) => {
            const { uploadsPath, renderMarkdown } = this.options;

            return handleFileEvent({
              files: event.clipboardData.files,
              uploadsPath,
              renderMarkdown,
              editor: extension.editor,
            });
          },
          handleDrop: (_, event) => {
            const { uploadsPath, renderMarkdown } = this.options;

            return handleFileEvent({
              files: event.dataTransfer.files,
              uploadsPath,
              renderMarkdown,
              editor: extension.editor,
            });
          },
        },
      }),
    ];
  },
}).configure({ inline: true });

export const serializer = (state, node) => {
  const { alt = '', canonicalSrc, src, title } = node.attrs;
  const quotedTitle = title ? ` ${state.quote(title)}` : '';

  state.write(`![${state.esc(alt)}](${state.esc(canonicalSrc || src)}${quotedTitle})`);
};

export const configure = (config) => ({
  tiptapExtension: ExtendedImage.configure({
    HTMLAttributes: {
      class: 'gl-w-full gl-h-auto',
    },
    ...config,
  }),
  serializer,
});
