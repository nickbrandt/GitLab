<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';
import FileStatusIcon from './repo_file_status_icon.vue';
import { leftSidebarViews } from '../constants';

export default {
  components: {
    FileStatusIcon,
    FileIcon,
    GlIcon,
    ChangedFileIcon,
  },
  props: {
    tab: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      tabMouseOver: false,
    };
  },
  computed: {
    ...mapGetters(['getUrlForPath', 'isFileActive', 'isCommitModeActive']),
    closeLabel() {
      if (this.isCommitModeActive) {
        return sprintf(__(`%{tabname} changed`), { tabname: this.tab.name });
      }
      return sprintf(__(`Close %{tabname}`, { tabname: this.tab.name }));
    },
    showChangedIcon() {
      if (this.isCommitModeActive) return true;

      return this.fileHasChanged ? !this.tabMouseOver : false;
    },
    fileHasChanged() {
      return this.tab.changed || this.tab.tempFile || this.tab.deleted;
    },
  },

  methods: {
    ...mapActions(['closeFile', 'openFile']),
    clickFile(tab) {
      if (this.isFileActive(tab)) return;

      this.openFile(tab.path);
    },
    mouseOverTab() {
      if (this.fileHasChanged) {
        this.tabMouseOver = true;
      }
    },
    mouseOutTab() {
      if (this.fileHasChanged) {
        this.tabMouseOver = false;
      }
    },
  },
};
</script>

<template>
  <li
    :class="{ active: isFileActive(tab) }"
    @click="clickFile(tab)"
    @mouseover="mouseOverTab"
    @mouseout="mouseOutTab"
  >
    <div :title="getUrlForPath(tab.path)" class="multi-file-tab">
      <file-icon :file-name="tab.name" :size="16" />
      {{ tab.name }}
      <file-status-icon :file="tab" />
    </div>
    <button
      :aria-label="closeLabel"
      type="button"
      class="multi-file-tab-close"
      @click.stop.prevent="closeFile(tab)"
    >
      <gl-icon v-if="!showChangedIcon" :size="12" name="close" />
      <changed-file-icon v-else :file="tab" />
    </button>
  </li>
</template>
