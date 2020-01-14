<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlDropdown, GlDropdownItem, GlFormGroup, GlSearchBoxByClick, GlAlert } from '@gitlab/ui';
import { scrollDown } from '~/lib/utils/scroll_utils';
import LogControlButtons from './log_control_buttons.vue';

export default {
  components: {
    GlAlert,
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    GlSearchBoxByClick,
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
    clusterApplicationsDocumentationPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchQuery: '',
      isElasticStackCalloutDismissed: false,
    };
  },
  computed: {
    ...mapState('environmentLogs', ['environments', 'logs', 'pods', 'enableAdvancedQuerying']),
    ...mapGetters('environmentLogs', ['trace']),
    showLoader() {
      return this.logs.isLoading || !this.logs.isComplete;
    },
    featureElasticEnabled() {
      return gon.features && gon.features.enableClusterApplicationElasticStack;
    },
    advancedFeaturesEnabled() {
      return this.featureElasticEnabled && this.enableAdvancedQuerying;
    },
    shouldShowElasticStackCallout() {
      return (
        !this.isElasticStackCalloutDismissed &&
        !this.environments.isLoading &&
        !this.advancedFeaturesEnabled
      );
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
      'setSearch',
      'showPodLogs',
      'showEnvironment',
      'fetchEnvironments',
    ]),
  },
};
</script>
<template>
  <div class="build-page-pod-logs mt-3">
    <gl-alert
      v-if="shouldShowElasticStackCallout"
      class="mb-3"
      @dismiss="isElasticStackCalloutDismissed = true"
    >
      {{
        s__(
          'Environments|Install Elastic Stack on your cluster to enable advanced querying capabilities such as full text search.',
        )
      }}
      <a :href="clusterApplicationsDocumentationPath">
        <strong>
          {{ s__('View Documentation') }}
        </strong>
      </a>
    </gl-alert>
    <div class="top-bar js-top-bar d-flex">
      <div class="row">
        <gl-form-group
          id="environments-dropdown-fg"
          :label="s__('Environments|Environment')"
          label-size="sm"
          label-for="environments-dropdown"
          :class="featureElasticEnabled ? 'col-4' : 'col-6'"
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
          id="pods-dropdown-fg"
          :label="s__('Environments|Pod logs from')"
          label-size="sm"
          label-for="pods-dropdown"
          :class="featureElasticEnabled ? 'col-4' : 'col-6'"
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
        <gl-form-group
          v-if="featureElasticEnabled"
          id="search-fg"
          :label="s__('Environments|Search')"
          label-size="sm"
          label-for="search"
          class="col-4"
        >
          <gl-search-box-by-click
            v-model.trim="searchQuery"
            :disabled="environments.isLoading || !advancedFeaturesEnabled"
            :placeholder="s__('Environments|Search')"
            class="js-logs-search"
            type="search"
            autofocus
            @submit="setSearch(searchQuery)"
          />
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
