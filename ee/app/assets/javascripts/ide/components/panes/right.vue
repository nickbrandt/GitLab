<script>
import { __ } from '~/locale';
import RightPane from '~/ide/components/panes/right.vue';
import TerminalView from '../terminal/view.vue';

export default {
  name: 'EERightPane',
  components: {
    RightPane,
  },
  data() {
    return {
      // this will come from Vuex store in https://gitlab.com/gitlab-org/gitlab-ee/issues/5426
      isTerminalEnabled: false,
    };
  },
  computed: {
    extensionTabs() {
      return [
        {
          show: this.isTerminalEnabled,
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
