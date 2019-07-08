<script>
import { GlLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { getPlatformLeaderKeyHTML } from '~/lib/utils/common_utils';

export default {
  components: {
    GlLink,
  },
  props: {
    markdownDocsPath: {
      type: String,
      required: true,
    },
    quickActionsDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    canAttachFile: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    indentHelpHtml() {
      const leader = getPlatformLeaderKeyHTML();
      const key1 = `<code>${leader}+[</code>`;
      const key2 = `<code>${leader}+]</code>`;
      return sprintf(s__('Editor|%{key1} and %{key2} to indent.'), { key1, key2 }, false);
    },
    toolbarHelpHtml() {
      const mdLinkStart = `<a href="${this.markdownDocsPath}" target="_blank" tabindex="-1">`;
      const mdLinkEnd = '</a>';
      const actionsLinkStart = `<a href="${this.quickActionsDocsPath}" target="_blank" tabindex="-1">`;
      const actionsLinkEnd = '</a>';

      if (this.markdownDocsPath && !this.quickActionsDocsPath) {
        return sprintf(
          s__('Editor|%{mdLinkStart}Markdown is supported.%{mdLinkEnd}'),
          { mdLinkStart, mdLinkEnd },
          false,
        );
      } else if (this.markdownDocsPath && this.quickActionsDocsPath) {
        return sprintf(
          s__(
            'Editor|%{mdLinkStart}Markdown%{mdLinkEnd} and %{actionsLinkStart}quick actions%{actionsLinkEnd} are supported.',
          ),
          { mdLinkStart, mdLinkEnd, actionsLinkStart, actionsLinkEnd },
          false,
        );
      }

      return null;
    },
  },
};
</script>

<template>
  <div class="comment-toolbar clearfix">
    <div class="toolbar-text">
      <span v-html="toolbarHelpHtml"></span>
      <span v-html="indentHelpHtml"></span>
    </div>
    <span v-if="canAttachFile" class="uploading-container">
      <span class="uploading-progress-container hide">
        <i class="fa fa-file-image-o toolbar-button-icon" aria-hidden="true"></i>
        <span class="attaching-file-message"></span>
        <span class="uploading-progress">0%</span>
        <span class="uploading-spinner">
          <i class="fa fa-spinner fa-spin toolbar-button-icon" aria-hidden="true"></i>
        </span>
      </span>
      <span class="uploading-error-container hide">
        <span class="uploading-error-icon">
          <i class="fa fa-file-image-o toolbar-button-icon" aria-hidden="true"></i>
        </span>
        <span class="uploading-error-message"></span>
        <button class="retry-uploading-link" type="button">Try again</button> or
        <button class="attach-new-file markdown-selector" type="button">attach a new file</button>
      </span>
      <button class="markdown-selector button-attach-file btn-link" tabindex="-1" type="button">
        <i class="fa fa-file-image-o toolbar-button-icon" aria-hidden="true"></i
        ><span class="text-attach-file">Attach a file</span>
      </button>
      <button class="btn btn-default btn-sm hide button-cancel-uploading-files" type="button">
        Cancel
      </button>
    </span>
  </div>
</template>
