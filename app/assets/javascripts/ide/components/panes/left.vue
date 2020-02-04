<script>
import { s__ } from '~/locale';
import { createNamespacedHelpers, mapActions, mapGetters, mapState } from 'vuex';
import { leftSidebarViews } from '../../constants';
import CollapsibleSidebar from './collapsible_sidebar.vue';
import ProjectAvatarDefault from '~/vue_shared/components/project_avatar/default.vue';
import IdeProjectHeader from '../ide_project_header.vue';
import IdeTree from '../ide_tree.vue';
import IdeReview from '../ide_review.vue';
import RepoCommitSection from '../repo_commit_section.vue';
import CommitForm from '../commit_sidebar/form.vue';

const { mapActions: mapLeftPaneActions } = createNamespacedHelpers('leftPane');

export default {
  name: 'LeftPane',
  components: {
    ProjectAvatarDefault,
    IdeProjectHeader,
    CollapsibleSidebar,
    CommitForm,
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
    leftExtensionTabs() {
      return [
        {
          show: true,
          title: s__('IDE|Edit'),
          views: [{ component: IdeTree, ...leftSidebarViews.ideTree }],
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
    ...mapLeftPaneActions(['open']),
    ...mapActions(['updateViewer']),
    openEditView() {
      this.open(this.leftExtensionTabs[0].views[0]);
    },
  },
};
</script>

<template>
  <collapsible-sidebar :extension-tabs="leftExtensionTabs" :side="'left'" :width="340">
    <template v-if="!loading" #header-icon>
      <a
        :href="currentProject.web_url"
        :title="s__('IDE|Go to project')"
        data-qa-selector="ide-header-icon"
        class="ide-header-icon ide-sidebar-link"
      >
        <project-avatar-default :project="currentProject" :size="48" />
      </a>
    </template>
    <template v-if="!loading" #header>
      <ide-project-header :project="currentProject" />
    </template>
    <template #footer>
      <commit-form />
    </template>
  </collapsible-sidebar>
</template>
