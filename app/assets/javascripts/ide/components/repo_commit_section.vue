<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import tooltip from '~/vue_shared/directives/tooltip';
import CommitFilesList from './commit_sidebar/list.vue';
import EmptyState from './commit_sidebar/empty_state.vue';

export default {
  components: {
    CommitFilesList,
    EmptyState,
  },
  directives: {
    tooltip,
  },
  computed: {
    ...mapState(['changedFiles', 'lastCommitMsg', 'activeFile']),
    ...mapState('commit', ['commitMessage', 'submitCommitLoading']),
    ...mapGetters(['lastOpenedFile', 'someUncommittedChanges']),
    ...mapGetters('commit', ['discardDraftButtonDisabled']),
    showStageUnstageArea() {
      return Boolean(this.someUncommittedChanges || this.lastCommitMsg);
    },
  },
  mounted() {
    this.initialize();
  },
  activated() {
    this.initialize();
  },
  methods: {
    ...mapActions(['updateViewer', 'updateActivityBarView', 'openFile', 'setFileActive']),
    initialize() {
      const file =
        this.lastOpenedFile && this.lastOpenedFile.type !== 'tree'
          ? this.lastOpenedFile
          : this.activeFile;

      if (!file) return null;

      return this.openFile(file.path).then(() => {
        this.updateViewer('diff');
      });
    },
  },
};
</script>

<template>
  <div class="multi-file-commit-panel-section">
    <template v-if="showStageUnstageArea">
      <commit-files-list
        key-prefix=""
        :file-list="changedFiles"
        :empty-state-text="__('There are no changes')"
        class="is-first"
        icon-name="unstaged"
      />
    </template>
    <empty-state v-else />
  </div>
</template>
