<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { modalTypes, viewerTypes } from '../constants';
import IdeTreeList from './ide_tree_list.vue';
import Upload from './new_dropdown/upload.vue';
import NewEntryButton from './new_dropdown/button.vue';
import NewModal from './new_dropdown/modal.vue';

export default {
  components: {
    Upload,
    IdeTreeList,
    NewEntryButton,
    NewModal,
  },
  computed: {
    ...mapState(['currentBranchId', 'activeFile']),
    ...mapGetters(['currentProject', 'currentTree', 'getUrlForPath']),
  },
  mounted() {
    this.initialize();
  },
  activated() {
    this.initialize();
  },
  methods: {
    ...mapActions(['updateViewer', 'createTempEntry', 'openFile', 'setFileActive']),
    createNewFile() {
      this.$refs.newModal.open(modalTypes.blob);
    },
    createNewFolder() {
      this.$refs.newModal.open(modalTypes.tree);
    },
    initialize() {
      if (this.activeFile && !this.activeFile.deleted) {
        this.openFile(this.activeFile.path).then(() => {
          this.updateViewer(viewerTypes.edit);
        });
      }
    },
  },
};
</script>

<template>
  <ide-tree-list>
    <template #header>
      {{ __('Edit') }}
      <div class="ide-tree-actions ml-auto d-flex">
        <new-entry-button
          :label="__('New file')"
          :show-label="false"
          class="d-flex border-0 p-0 mr-3 qa-new-file"
          icon="doc-new"
          @click="createNewFile()"
        />
        <upload
          :show-label="false"
          class="d-flex mr-3"
          button-css-classes="border-0 p-0"
          @create="createTempEntry"
        />
        <new-entry-button
          :label="__('New directory')"
          :show-label="false"
          class="d-flex border-0 p-0"
          icon="folder-new"
          @click="createNewFolder()"
        />
      </div>
      <new-modal ref="newModal" />
    </template>
  </ide-tree-list>
</template>
