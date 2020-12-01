<script>
import { GlFriendlyWrap, GlLink } from '@gitlab/ui';
import { dynI8n } from "../dynamic_i8n";

export default {
  name: 'ReportItemUrl',
  components: {
    GlLink,
    GlFriendlyWrap
  },
  props: {
    text: {
      type: Array,
      default: ()=> [],
      required: false,
    },
    href: {
      type: String,
      required: true,
    }
  },
  computed: {
    linkText() {
      let res = "";
      if (this.text.length > 0) {
        res = dynI8n(this.text);
      } else {
        res = this.href;
      }
      return res;
    }
  },
}
</script>

<template>
  <div>
    <gl-link :href="href" target="_blank">
      <gl-friendly-wrap :text="linkText" />
    </gl-link>
  </div>
</template>
