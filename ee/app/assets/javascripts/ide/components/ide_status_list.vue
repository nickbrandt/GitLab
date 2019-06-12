<script>
import IdeStatusList from '~/ide/components/ide_status_list.vue';
import TerminalSyncStatusSafe from './terminal_sync/terminal_sync_status_safe.vue';

export default {
  components: {
    IdeStatusList,
    TerminalSyncStatusSafe,
  },
};
</script>

<template>
  <ide-status-list>
    <terminal-sync-status-safe />
  </ide-status-list>
</template>
