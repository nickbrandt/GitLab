<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { truncateSha } from '~/lib/utils/text_utility';
import Icon from '~/vue_shared/components/icon.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ExpandButton from '~/vue_shared/components/expand_button.vue';

export default {
  name: 'EvidenceBlock',
  components: {
    ClipboardButton,
    ExpandButton,
    GlLink,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    release: {
      type: Object,
      required: true,
    },
  },
  computed: {
    evidences() {
      return this.release.evidences;
    },
  },
  methods: {
    evidenceTitle(index) {
      const [tag, filename] = this.release.evidences[index].filepath.split('/').slice(-2);
      return sprintf(__(`${tag}-${filename}`));
    },
    evidenceUrl(index) {
      return this.release.evidences[index].filepath;
    },
    sha(index) {
      return this.release.evidences[index].sha;
    },
    shortSha(index) {
      return truncateSha(this.release.evidences[index].sha);
    },
  },
};
</script>

<template>
  <div>
    <div class="card-text prepend-top-default">
      <b>
        {{ __('Evidence collection') }}
      </b>
    </div>
    <div v-for="(evidence, index) in evidences" :key="index" class="d-flex align-items-baseline">
      <gl-link
        v-gl-tooltip
        class="monospace"
        :title="__('Download evidence JSON')"
        :download="evidenceTitle(index)"
        :href="evidenceUrl(index)"
      >
        <icon name="review-list" class="align-top append-right-4" /><span>
          {{ evidenceTitle(index) }}
        </span>
      </gl-link>

      <expand-button>
        <template slot="short">
          <span class="js-short monospace">{{ shortSha(index) }}</span>
        </template>
        <template slot="expanded">
          <span class="js-expanded monospace gl-pl-1">{{ sha(index) }}</span>
        </template>
      </expand-button>
      <clipboard-button
        :title="__('Copy commit SHA')"
        :text="sha(index)"
        css-class="btn-default btn-transparent btn-clipboard"
      />
    </div>
  </div>
</template>
