<script>
/* eslint-disable vue/no-v-html */
import { GlLoadingIcon } from '@gitlab/ui';
import { dynI8n } from '../dynamic_i8n';
import axios from '~/lib/utils/axios_utils';

export default {
  name: 'ReportItemMarkdown',
  components: { GlLoadingIcon },
  props: {
    value: {
      type: Array,
      required: true,
    },
    markdownEndpoint: {
      type: String,
      default: '/api/v4/markdown',
      required: false,
    },
    vuln: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      markdown: '',
      loading: true,
      loadError: false,
      error: false,
    };
  },
  mounted() {
    this.renderMarkdown();
  },
  methods: {
    renderMarkdown() {
      const langValue = dynI8n(this.value);
      axios
        .post(this.markdownEndpoint, {
          text: langValue,
          gfm: true,
          project: this.vuln.project.full_path.slice(1),
        })
        .then((res) => res.data)
        .then((data) => {
          this.markdown = data.html;
          this.loading = false;
        })
        .catch((e) => {
          if (e.status !== 200) {
            this.loadError = true;
          }
          this.error = true;
        });
    },
  },
};
</script>

<template>
  <div>
    <div v-if="loading && !error" class="text-center loading">
      <gl-loading-icon class="mt-5" size="lg" />
    </div>
    <div v-if="!loading && !error" v-html="markdown"></div>
  </div>
</template>
