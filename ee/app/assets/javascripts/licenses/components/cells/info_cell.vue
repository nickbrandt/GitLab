<script>
import { GlPopover } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import Cell from './cell.vue';

export default {
  name: 'InfoCell',
  components: {
    Icon,
    GlPopover,
    Cell,
  },
  props: {
    title: {
      type: String,
      required: true,
      default: null,
    },
    value: {
      type: [Number, String],
      required: false,
      default: null,
    },
    popoverContent: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      popoverTarget: null,
    };
  },
  mounted() {
    this.popoverTarget = this.$refs.popoverTarget;
  },
};
</script>

<template>
  <cell class="license-info-cell" :value="value">
    <template slot="title">
      <span class="mr-2 text">{{ title }}</span>

      <button ref="popoverTarget" type="button" class="btn-link information-target">
        <icon name="information" class="icon d-block" />
      </button>

      <gl-popover
        placement="bottom"
        :target="popoverTarget"
        :content="popoverContent"
        triggers="hover"
      />
    </template>
  </cell>
</template>
