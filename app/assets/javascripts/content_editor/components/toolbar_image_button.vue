<script>
import {
  GlDropdown,
  GlDropdownForm,
  GlButton,
  GlFormInputGroup,
  GlDropdownDivider,
  GlDropdownItem,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { Editor as TiptapEditor } from '@tiptap/vue-2';

export default {
  components: {
    GlDropdown,
    GlDropdownForm,
    GlFormInputGroup,
    GlDropdownDivider,
    GlDropdownItem,
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  props: {
    tiptapEditor: {
      type: TiptapEditor,
      required: true,
    },
  },
  data() {
    return {
      imgAlt: '',
      imgSrc: '',
      isLoading: false,
      error: '',
    };
  },
  methods: {
    emitExecute(source = 'url') {
      this.$emit('execute', { contentType: 'image', value: source });
    },
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    onUploadChange(e) {
      this.tiptapEditor.chain().focus().uploadImage({ file: e.target.files[0] }).run();
      // await this.uploadFile(e.target.files[0]);
      this.emitExecute('upload');
    },
  },
};
</script>
<template>
  <gl-dropdown
    v-gl-tooltip
    :aria-label="__('Insert image')"
    :title="__('Insert image')"
    size="small"
    category="tertiary"
    icon="media"
  >
    <gl-dropdown-form class="gl-px-3!">
      <gl-form-input-group v-model="imgSrc" :placeholder="__('Image URL')">
        <template #append>
          <gl-button
            variant="confirm"
            @click="
              insertImage();
              emitExecute();
            "
            >{{ __('Insert') }}</gl-button
          >
        </template>
      </gl-form-input-group>
    </gl-dropdown-form>
    <gl-dropdown-divider />
    <gl-dropdown-item @click="openFileUpload">
      {{ __('Upload image') }}
    </gl-dropdown-item>

    <input
      ref="fileUpload"
      type="file"
      name="content_editor_image"
      :accept="$options.acceptedMimes"
      class="gl-display-none"
      @change="onUploadChange"
    />
  </gl-dropdown>
</template>
