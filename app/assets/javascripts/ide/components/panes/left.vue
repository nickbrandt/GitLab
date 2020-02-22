<script>
import { s__ } from '~/locale';
import { mapActions, mapGetters, mapState } from 'vuex';
import { leftSidebarViews } from '../../constants';
import { GlSkeletonLoading } from '@gitlab/ui';
import CommitForm from '../commit_sidebar/form.vue';
import IdeSideBar from '../ide_side_bar.vue';
import IdeTree from '../ide_tree.vue';
import IdeReview from '../ide_review.vue';
import RepoCommitSection from '../repo_commit_section.vue';
import ResizablePanel from '../resizable_panel.vue';
import IdeProjectHeader from '../ide_project_header.vue';

export default {
  name: 'LeftPane',
  components: {
    CommitForm,
    GlSkeletonLoading,
    IdeSideBar,
    IdeProjectHeader,
    ResizablePanel,
  },
  props: {
    extensionTabs: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    ...mapState(['loading']),
    ...mapGetters(['currentProject', 'hasChanges']),
    tabs() {
      return [
        {
          show: true,
          title: s__('IDE|Edit'),
          views: [{ component: IdeTree, ...leftSidebarViews.edit }],
          icon: 'code',
          buttonClasses: ['js-ide-edit-mode'],
        },
        {
          show: true,
          title: s__('IDE|Review'),
          views: [{ component: IdeReview, ...leftSidebarViews.review }],
          icon: 'file-modified',
          buttonClasses: ['js-ide-review-mode'],
        },
        {
          show: this.hasChanges,
          title: s__('IDE|Commit'),
          views: [{ component: RepoCommitSection, ...leftSidebarViews.commit }],
          icon: 'commit',
          buttonClasses: ['js-ide-commit-mode', 'qa-commit-mode-tab'],
        },
        ...this.extensionTabs,
      ];
    },
  },
  watch: {
    hasChanges(newVal) {
      if (!newVal) {
        this.openEditView();
      }
    },
  },
  mounted() {
    this.openEditView();
  },
  methods: {
    ...mapActions(['updateActivityBarView']),
    openEditView() {
      this.updateActivityBarView(this.tabs[0].views[0].name);
    },
  },
};
</script>

<template>
  <resizable-panel
    :initial-width="340"
    :min-size="340"
    side="left"
    :collapsible="false"
    class="d-flex flex-column"
  >
    <template v-if="loading">
      <div class="multi-file-commit-panel-inner">
        <div v-for="n in 3" :key="n" class="multi-file-loading-container">
          <gl-skeleton-loading />
        </div>
      </div>
    </template>
    <template v-else>
      <ide-project-header :project="currentProject" />
      <ide-side-bar :tabs="tabs" :side="'left'">
        <template #footer>
          <commit-form />
        </template>
      </ide-side-bar>
    </template>
  </resizable-panel>
</template>
