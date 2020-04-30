<script>
import { mapGetters } from 'vuex';
import { sprintf, s__ } from '~/locale';
import { GlIcon } from '@gitlab/ui';
import formattingMixins from '../formatting_mixins';
import SummaryDetails from './order_summary/summary_details.vue';

export default {
  components: {
    SummaryDetails,
    GlIcon,
  },
  mixins: [formattingMixins],
  data() {
    return {
      collapsed: true,
    };
  },
  computed: {
    ...mapGetters(['totalAmount', 'name', 'usersPresent']),
    titleWithName() {
      return sprintf(this.$options.i18n.title, { name: this.name });
    },
  },
  methods: {
    toggleCollapse() {
      this.collapsed = !this.collapsed;
    },
  },
  i18n: {
    title: s__("Checkout|%{name}'s GitLab subscription"),
  },
};
</script>
<template>
  <div class="order-summary d-flex flex-column flex-grow-1 prepend-top-5 mt-lg-5">
    <div class="d-lg-none">
      <div @click="toggleCollapse">
        <h4
          class="d-flex justify-content-between gl-font-lg"
          :class="{ 'prepend-bottom-32': !collapsed }"
        >
          <div class="d-flex">
            <gl-icon v-if="collapsed" name="chevron-right" :size="18" />
            <gl-icon v-else name="chevron-down" :size="18" />
            <div>{{ titleWithName }}</div>
          </div>
          <div class="prepend-left-default">{{ formatAmount(totalAmount, usersPresent) }}</div>
        </h4>
      </div>
      <summary-details v-show="!collapsed" />
    </div>
    <div class="d-none d-lg-block">
      <div class="append-bottom-20">
        <h4 class="gl-font-size-20-deprecated-no-really-do-not-use-me">
          {{ titleWithName }}
        </h4>
      </div>
      <summary-details />
    </div>
  </div>
</template>
