<script>
import { GlFriendlyWrap, GlLink } from '@gitlab/ui';

export default {
  name: 'ReportItemLink',
  components: {
    GlLink,
    GlFriendlyWrap
  },
  props: {
    url: {
      type: String,
      required: true,
    },
    text: {
      type: String,
      default: null,
      required: false,
    },
    alt: {
      type: String,
      default: null,
      required: false,
    }
  },
  computed: {
    linkText() {
      let res = "";
      if (this.text) {
        res = this.text;
      } else {
        res = this.url;
      }
      return res;
    }
  }
}
</script>

<template>
  <div>
    <gl-link :ref="alt" :href="url" target="_blank">
      <gl-friendly-wrap :text="linkText" />
    </gl-link>
  </div>
</template>
