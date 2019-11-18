<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlDropdown, GlDropdownItem, GlFormGroup, GlButton, GlTooltipDirective } from '@gitlab/ui';
import {
  canScroll,
  isScrolledToTop,
  isScrolledToBottom,
  scrollDown,
  scrollUp,
} from '~/lib/utils/scroll_utils';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    GlButton,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    environmentId: {
      type: String,
      required: true,
    },
    projectFullPath: {
      type: String,
      required: true,
    },
    currentEnvironmentName: {
      type: String,
      required: false,
      default: '',
    },
    currentPodName: {
      type: [String, null],
      required: false,
      default: null,
    },
    environmentsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      scrollToTopEnabled: false,
      scrollToBottomEnabled: false,
    };
  },
  computed: {
    ...mapState('environmentLogs', ['environments', 'logs', 'pods']),
    ...mapGetters('environmentLogs', ['trace']),
    showLoader() {
      return this.logs.isLoading || !this.logs.isComplete;
    },
  },
  watch: {
    trace(val) {
      this.$nextTick(() => {
        if (val) {
          this.scrollDown();
        } else {
          this.updateScrollState();
        }
      });
    },
  },
  created() {
    window.addEventListener('scroll', this.updateScrollState);
  },
  mounted() {
    this.setInitData({
      projectPath: this.projectFullPath,
      environmentId: this.environmentId,
      podName: this.currentPodName,
    });

    this.fetchEnvironments(this.environmentsPath);
  },
  destroyed() {
    window.removeEventListener('scroll', this.updateScrollState);
  },
  methods: {
    ...mapActions('environmentLogs', ['setInitData', 'showPodLogs', 'fetchEnvironments']),
    updateScrollState() {
      this.scrollToTopEnabled = canScroll() && !isScrolledToTop();
      this.scrollToBottomEnabled = canScroll() && !isScrolledToBottom();
    },
    scrollUp,
    scrollDown,
  },
};
</script>
<template>
  <div class="build-page-pod-logs mt-3">
    <div class="top-bar d-flex">
      <div class="row">
        <gl-form-group
          id="environments-dropdown-fg"
          :label="s__('Environments|Environment')"
          label-size="sm"
          label-for="environments-dropdown"
          class="col-6"
        >
          <gl-dropdown
            id="environments-dropdown"
            :text="currentEnvironmentName"
            :disabled="environments.isLoading"
            class="d-flex js-environments-dropdown"
            toggle-class="dropdown-menu-toggle"
          >
            <gl-dropdown-item
              v-for="env in environments.options"
              :key="env.id"
              :href="env.logs_path"
            >
              {{ env.name }}
            </gl-dropdown-item>
          </gl-dropdown>
        </gl-form-group>
        <gl-form-group
          id="environments-dropdown-fg"
          :label="s__('Environments|Pod logs from')"
          label-size="sm"
          label-for="pods-dropdown"
          class="col-6"
        >
          <gl-dropdown
            id="pods-dropdown"
            :text="pods.current || s__('Environments|No pods to display')"
            :disabled="logs.isLoading"
            class="d-flex js-pods-dropdown"
            toggle-class="dropdown-menu-toggle"
          >
            <gl-dropdown-item
              v-for="podName in pods.options"
              :key="podName"
              @click="showPodLogs(podName)"
            >
              {{ podName }}
            </gl-dropdown-item>
          </gl-dropdown>
        </gl-form-group>
      </div>
      <div class="controllers align-self-end">
        <div
          v-gl-tooltip
          class="controllers-buttons"
          :title="__('Scroll to top')"
          aria-labelledby="scroll-to-top"
        >
          <gl-button
            id="scroll-to-top"
            class="btn-blank js-scroll-to-top"
            :aria-label="__('Scroll to top')"
            :disabled="!scrollToTopEnabled"
            @click="scrollUp()"
            ><icon name="scroll_up"
          /></gl-button>
        </div>
        <div
          v-gl-tooltip
          class="controllers-buttons"
          :title="__('Scroll to bottom')"
          aria-labelledby="scroll-to-bottom"
        >
          <gl-button
            id="scroll-to-bottom"
            class="btn-blank js-scroll-to-bottom"
            :aria-label="__('Scroll to bottom')"
            :disabled="!scrollToBottomEnabled"
            @click="scrollDown()"
            ><icon name="scroll_down"
          /></gl-button>
        </div>
        <gl-button
          id="refresh-log"
          v-gl-tooltip
          class="ml-1 px-2 js-refresh-log"
          :title="__('Refresh')"
          :aria-label="__('Refresh')"
          @click="showPodLogs(pods.current)"
        >
          <icon name="retry" />
        </gl-button>
      </div>
    </div>
    <pre class="build-trace js-log-trace"><code class="bash">{{trace}}
      <div v-if="showLoader" class="build-loader-animation js-build-loader-animation">
        <div class="dot"></div>
        <div class="dot"></div>
        <div class="dot"></div>
      </div></code></pre>
  </div>
</template>
