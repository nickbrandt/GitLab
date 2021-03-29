<script>
import { GlForm, GlFormInput, GlFormInputGroup, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlForm,
    GlFormInput,
    GlFormInputGroup,
    GlButton
  },

  props: {
  },
  computed: {
  },
};
</script>
<template>
  <gl-form>
    <gl-form-input-group class="gl-corpus-name">
      <slot name="input">
        <gl-form-input
          ref="input"
        />
      </slot>

      <gl-button
        class="gl-search-box-by-click-icon-button gl-search-box-by-click-clear-button gl-clear-icon-button"
        variant="default"
        category="tertiary"
        size="small"
        name="clear"
        title="title"
        icon="clear"
        aria-label="Clear"
      />

    </gl-form-input-group>

    <gl-form-input-group 
      label="Corpus file"
      label-size="sm"
    >
      <gl-button>Choose file...</gl-button>

    </gl-form-input-group>

  </gl-form>
</template>
