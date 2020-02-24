<script>
import { mapGetters, mapState } from 'vuex';
import { GlSkeletonLoading } from '@gitlab/ui';
import CollapsibleSidebar from './panes/collapsible_sidebar.vue';
import IdeTree from './ide_tree.vue';
import IdeReview from './ide_review.vue';
import RepoCommitSection from './repo_commit_section.vue';
import CommitForm from './commit_sidebar/form.vue';
import IdeProjectHeader from './ide_project_header.vue';
import ResizablePanel from './resizable_panel.vue';
import { s__ } from '~/locale';

export default {
  components: {
    CollapsibleSidebar,
    CommitForm,
    IdeProjectHeader,
    ResizablePanel,
    GlSkeletonLoading,
  },
  computed: {
    ...mapGetters(['hasChanges', 'currentProject']),
    ...mapState('leftPane', ['isOpen']),
    ...mapState(['loading']),
    tabs() {
      return [
        {
          show: true,
          title: s__('IDE|Edit'),
          views: [{ component: IdeTree, keepAlive: true, name: 'ide-tree' }],
          icon: 'code',
        },
        {
          show: true,
          title: s__('IDE|Review'),
          views: [{ component: IdeReview, keepAlive: true, name: 'ide-review' }],
          icon: 'file-modified',
        },
        {
          show: this.hasChanges,
          title: s__('IDE|Commit'),
          views: [{ component: RepoCommitSection, keepAlive: true, name: 'repo-commit-section' }],
          icon: 'commit',
        },
      ];
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
    :resizable="isOpen"
    class="d-flex flex-column"
    :class="{ 'w-auto': !isOpen }"
  >
    <div v-if="loading" class="multi-file-commit-panel-inner">
      <div v-for="n in 3" :key="n" class="multi-file-loading-container">
        <gl-skeleton-loading />
      </div>
    </div>
    <template v-else>
      <ide-project-header :project="currentProject" :expanded="isOpen" class="w-100" />
      <div class="ide-context-body d-flex flex-fill w-100">
        <collapsible-sidebar :extension-tabs="tabs" side="left" :class="{ 'w-100': isOpen }">
          <template v-slot="{ component }">
            <div class="multi-file-commit-panel-inner">
              <div class="multi-file-commit-panel-inner-content">
                <component :is="component" />
              </div>
              <commit-form />
            </div>
          </template>
        </collapsible-sidebar>
      </div>
    </template>
  </resizable-panel>
</template>
