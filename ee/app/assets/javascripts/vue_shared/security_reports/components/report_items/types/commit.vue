<script>
import { GlFriendlyWrap, GlLink } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { getBaseURL } from '~/lib/utils/url_utility';

export default {
  name: 'ReportItemCommit',
  components: {
    ClipboardButton,
    GlFriendlyWrap,
    GlLink,
  },
  props: {
    vuln: {
      type: Object,
      required: true,
    },
    value: {
      type: String,
      required: true,
    },
  },
  computed: {
    linkToCommit() {
      const base = getBaseURL();
      const { project } = this.vuln;
      return `${base}/${project.full_path}/-/commit/${this.value}`;
    },
    shortSha() {
      return this.value.substring(0, 8);
    },
  },
};
</script>

<template>
  <div class="d-flex">
    <gl-link ref="commitLink" :href="linkToCommit" target="_blank" class="commit-sha">
      <gl-friendly-wrap :text="shortSha" />
    </gl-link>
    <clipboard-button
      :text="value"
      :title="__('Copy commit SHA')"
      css-class="btn-clipboard"
      tooltip-placement="bottom"
    />
  </div>
</template>
