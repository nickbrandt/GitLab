<script>
import { GlTooltipDirective, GlButton, GlIcon } from '@gitlab/ui';

export default {
  name: 'ReplyButton',
  components: {
    GlIcon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <div class="note-actions-item">
    <gl-button
      ref="button"
      v-gl-tooltip
      class="note-action-button"
      data-track-event="click_button"
      data-track-label="reply_comment_button"
      category="tertiary"
      :title="__('Reply to comment')"
      @click="$emit('startReplying')"
    >
      <gl-icon name="comment" class="link-highlight" />
    </gl-button>
  </div>
</template>
