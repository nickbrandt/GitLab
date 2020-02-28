<script>
import { mapGetters, mapState } from 'vuex';
import { __ } from '~/locale';
import CollapsibleSidebar from './collapsible_sidebar.vue';
import ResizablePanel from '../resizable_panel.vue';
import { rightSidebarViews } from '../../constants';
import PipelinesList from '../pipelines/list.vue';
import JobsDetail from '../jobs/detail.vue';
import Clientside from '../preview/clientside.vue';

export default {
  name: 'RightPane',
  components: {
    CollapsibleSidebar,
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
    ...mapState(['currentMergeRequestId', 'clientsidePreviewEnabled']),
    ...mapState('rightPane', ['isOpen']),
    ...mapGetters(['packageJson']),
    showLivePreview() {
      return this.packageJson && this.clientsidePreviewEnabled;
    },
    tabs() {
      return [
        {
          show: true,
          title: __('Pipelines'),
          views: [
            { component: PipelinesList, ...rightSidebarViews.pipelines },
            { component: JobsDetail, ...rightSidebarViews.jobsDetail },
          ],
          icon: 'rocket',
        },
        {
          show: this.showLivePreview,
          title: __('Live preview'),
          views: [{ component: Clientside, ...rightSidebarViews.clientSidePreview }],
          icon: 'live-preview',
        },
        ...this.extensionTabs,
      ];
    },
  },
};
</script>

<template>
  <resizable-panel
    :initial-width="410"
    :min-size="350"
    side="right"
    :collapsible="false"
    :resizable="isOpen"
  >
    <collapsible-sidebar :extension-tabs="tabs" side="right" class="h-100 w-100" />
  </resizable-panel>
</template>
