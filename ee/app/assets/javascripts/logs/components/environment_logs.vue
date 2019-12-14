<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlDropdown, GlDropdownItem, GlFormGroup } from '@gitlab/ui';
import { scrollDown } from '~/lib/utils/scroll_utils';
import LogControlButtons from './log_control_buttons.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    LogControlButtons,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    environmentName: {
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
          scrollDown();
        }
        this.$refs.scrollButtons.update();
      });
    },
  },
  mounted() {
    this.setInitData({
      projectPath: this.projectFullPath,
      environmentName: this.environmentName,
      podName: this.currentPodName,
    });

    this.fetchEnvironments(this.environmentsPath);
  },
  methods: {
    ...mapActions('environmentLogs', [
      'setInitData',
      'showPodLogs',
      'showEnvironment',
      'fetchEnvironments',
    ]),
  },
};
</script>
<template>
  <div class="build-page-pod-logs mt-3">
    <div class="top-bar js-top-bar d-flex">
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
            :text="environments.current"
            :disabled="environments.isLoading"
            class="d-flex js-environments-dropdown"
            toggle-class="dropdown-menu-toggle"
          >
            <gl-dropdown-item
              v-for="env in environments.options"
              :key="env.id"
              @click="showEnvironment(env.name)"
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

      <log-control-buttons
        ref="scrollButtons"
        class="controllers align-self-end"
        @refresh="showPodLogs(pods.current)"
      />
    </div>
    <pre class="build-trace js-log-trace"><code class="bash js-build-output">{{trace}}
      <div v-if="showLoader" class="build-loader-animation js-build-loader-animation">
        <div class="dot"></div>
        <div class="dot"></div>
        <div class="dot"></div>
      </div></code></pre>
  </div>
</template>
