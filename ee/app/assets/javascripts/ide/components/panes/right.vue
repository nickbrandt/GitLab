<script>
import { mapState } from 'vuex';
import { __ } from '~/locale';
import RightPane from '~/ide/components/panes/right.vue';
import TerminalView from '../terminal/view.vue';

export default {
  name: 'EERightPane',
  components: {
    RightPane,
  },
  computed: {
    ...mapState('terminal', {
      isTerminalVisible: 'isVisible',
    }),
    extensionTabs() {
      return [
        {
          show: this.isTerminalVisible,
          title: __('Terminal'),
          views: [{ name: 'terminal', keepAlive: true, component: TerminalView }],
          icon: 'terminal',
        },
      ];
    },
  },
};
</script>

<template>
  <right-pane :extension-tabs="extensionTabs" />
</template>
