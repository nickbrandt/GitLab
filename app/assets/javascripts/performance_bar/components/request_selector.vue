<script>
import { glEmojiTag } from '~/emoji';

export default {
  props: {
    currentRequest: {
      type: Object,
      required: true,
    },
    requests: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      currentRequestId: this.currentRequest.id,
    };
  },
  computed: {
    anyRequestsWithWarnings() {
      return this.requests.some(request => request.hasWarnings);
    },
  },
  watch: {
    currentRequestId(newRequestId) {
      this.$emit('change-current-request', newRequestId);
    },
  },
  methods: {
    truncatedUrl(requestUrl) {
      const components = requestUrl.replace(/\/$/, '').split('/');
      let truncated = components[components.length - 1];

      if (truncated.match(/^\d+$/)) {
        truncated = `${components[components.length - 2]}/${truncated}`;
      }

      return truncated;
    },
    glEmojiTag,
  },
};
</script>
<template>
  <div id="peek-request-selector">
    <select v-model="currentRequestId">
      <option
        v-for="request in requests"
        :key="request.id"
        :value="request.id"
        class="qa-performance-bar-request"
      >
        {{ truncatedUrl(request.url) }}
        <span v-if="request.hasWarnings" v-html="glEmojiTag('warning')"></span>
      </option>
    </select>
    <span v-if="anyRequestsWithWarnings" v-html="glEmojiTag('warning')"></span>
  </div>
</template>
