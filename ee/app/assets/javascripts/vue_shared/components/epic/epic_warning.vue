<script>
import { mapGetters } from 'vuex';
import { GlIcon, GlLink } from '@gitlab/ui';
import * as constants from '~/notes/constants';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    isConfidential: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    ...mapGetters(['getNoteableDataByProp']),
    isNoteableTypeEpic() {
      return this.getNoteableDataByProp('noteableType') === constants.EPIC_NOTEABLE_TYPE;
    },
    confidentialEpicDocsPath() {
      return this.getNoteableDataByProp('confidential_epics_docs_path');
    },
  },
};
</script>

<template>
  <div v-if="isNoteableTypeEpic && isConfidential" ref="epicWarning" class="issuable-note-warning">
    <gl-icon name="eye-slash" :size="16" class="icon" />
    <span ref="confidential">
      {{ __('This is a confidential epic.') }}
      {{ __('People without permission will never get a notification.') }}
      <gl-link :href="confidentialEpicDocsPath" target="_blank">
        {{ __('Learn more') }}
      </gl-link>
    </span>
  </div>
</template>
