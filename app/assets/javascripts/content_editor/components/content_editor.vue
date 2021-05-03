<script>
import { EditorContent as TiptapEditorContent } from '@tiptap/vue-2';
import Vue from 'vue';
import { __ } from '~/locale';
import { ContentEditor } from '../services/content_editor';
import ContentEditorAdapter from './content_editor_adapter.vue';
import TopToolbar from './top_toolbar.vue';

const TOOLBAR_BUTTONS = [
  {
    contentType: 'bold',
    iconName: 'bold',
    editorCommand: 'toggleBold',
    label: __('Bold text'),
  },
  {
    contentType: 'italic',
    iconName: 'italic',
    editorCommand: 'toggleItalic',
    label: __('Italic text'),
  },
  {
    contentType: 'code',
    iconName: 'code',
    editorCommand: 'toggleCode',
    label: __('Code'),
  },
  {
    contentType: 'blockquote',
    iconName: 'quote',
    editorCommand: 'toggleBlockquote',
    label: __('Insert a quote'),
  },
  {
    contentType: 'bulletList',
    iconName: 'list-bulleted',
    editorCommand: 'toggleBulletList',
    label: __('Add a bullet list'),
  },
  {
    contentType: 'orderedList',
    iconName: 'list-numbered',
    editorCommand: 'toggleOrderedList',
    label: __('Add a numbered list'),
  },
];

const EXTENSIONS = TOOLBAR_BUTTONS.map(({ contentType }) => ({
  setReactiveState(editor, reactiveState) {
    Vue.set(reactiveState.toolbar, contentType, {
      isActive: editor.isFocused && editor.isActive(contentType),
    });

    console.log(contentType, JSON.parse(JSON.stringify(reactiveState.toolbar[contentType])));
  },
}));

export default {
  components: {
    ContentEditorAdapter,
    TiptapEditorContent,
    TopToolbar,
  },
  props: {
    contentEditor: {
      type: ContentEditor,
      required: true,
    },
  },
  EXTENSIONS,
  TOOLBAR_BUTTONS,
};
</script>
<template>
  <content-editor-adapter :content-editor="contentEditor" :extensions="$options.EXTENSIONS">
    <template #default="{ isFocused, toolbar }">
      <div class="md md-area" :class="{ 'is-focused': isFocused }">
        <top-toolbar
          class="gl-mb-4"
          :content-editor="contentEditor"
          :toolbar-state="toolbar"
          :toolbar-buttons="$options.TOOLBAR_BUTTONS"
        />
        <tiptap-editor-content :editor="contentEditor.tiptapEditor" />
      </div>
    </template>
  </content-editor-adapter>
</template>
