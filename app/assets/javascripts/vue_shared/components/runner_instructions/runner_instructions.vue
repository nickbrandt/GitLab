<script>
import {
  GlAlert,
  GlButton,
  GlModal,
  GlModalDirective,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import getRunnerPlatforms from './graphql/queries/get_runner_platforms.query.graphql';
import getRunnerSetupInstructions from './graphql/queries/get_runner_setup.query.graphql';
import getRunnerSetupInstructionsGroup from './graphql/queries/get_runner_setup_group.query.graphql';
import getRunnerSetupInstructionsAdmin from './graphql/queries/get_runner_setup_admin.query.graphql';
import getProjectId from './graphql/queries/get_project_id.query.graphql';
import getGroupId from './graphql/queries/get_group_id.query.graphql';

export default {
  components: {
    GlAlert,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlModal,
    GlIcon,
  },
  directives: {
    GlModalDirective,
  },
  inject: {
    projectPath: {
      default: '',
    },
    groupPath: {
      default: '',
    },
  },
  apollo: {
    runnerPlatforms: {
      query: getRunnerPlatforms,
      update(data) {
        return data?.runnerPlatforms?.nodes;
      },
      error() {
        this.showAlert = true;
      },
    },
    projectId: {
      query: getProjectId,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        return data?.project?.id;
      },
      error() {
        this.showAlert = true;
      },
    },
    groupId: {
      query: getGroupId,
      variables() {
        return {
          groupPath: this.groupPath,
        };
      },
      update(data) {
        return data?.group?.id;
      },
      error() {
        this.showAlert = true;
      },
    },
  },
  data() {
    return {
      showAlert: false,
      selectedPlatformArchitectures: [],
      selectedPlatform: {},
      selectedArchitecture: {},
      runnerPlatforms: [],
      projectId: '',
      groupId: '',
      instructions: {},
    };
  },
  computed: {
    closeButton() {
      return {
        text: __('Close'),
        attributes: [{ variant: 'default' }],
      };
    },
    isPlatformSelected() {
      return Object.keys(this.selectedPlatform).length > 0;
    },
    instructionsEmpty() {
      return this.instructions == null || Object.keys(this.instructions).length === 0;
    },
  },
  methods: {
    selectPlatform(name) {
      this.selectedPlatform = this.runnerPlatforms.find(platform => platform.name === name);
      this.selectedPlatformArchitectures = this.selectedPlatform?.architectures?.nodes;
      [this.selectedArchitecture] = this.selectedPlatformArchitectures;
      this.selectArchitecture(this.selectedArchitecture.name);
    },
    selectArchitecture(name) {
      this.selectedArchitecture = this.selectedPlatformArchitectures.find(
        architecture => architecture.name === name,
      );

      this.$apollo.addSmartQuery('instructions', {
        variables() {
          const vars = {
            platform: this.selectedPlatform.name,
            architecture: this.selectedArchitecture.name,
          };
          if (this.projectId) {
            vars.projectId = this.projectId;
          }

          if (this.groupId) {
            vars.groupId = this.groupId;
          }

          return vars;
        },
        query() {
          if (this.projectId) {
            return getRunnerSetupInstructions;
          } else if (this.groupId) {
            return getRunnerSetupInstructionsGroup;
          }

          return getRunnerSetupInstructionsAdmin;
        },
        update(data) {
          return data?.runnerSetup;
        },
        error() {
          this.showAlert = true;
        },
      });
    },
    toggleAlert(state) {
      this.showAlert = state;
    },
  },
  modalId: 'installation-instructions-modal',
  i18n: {
    installARunner: __('Install a Runner'),
    architecture: __('Architecture'),
    downloadInstallBinary: s__('Runners|Download and Install Binary'),
    downloadLatestBinary: s__('Runners|Download Latest Binary'),
    registerRunner: s__('Runners|Register Runner'),
    method: __('Method'),
    genericError: __('An error has occurred'),
    instructions: __('Show Runner installation instructions'),
  },
};
</script>
<template>
  <div>
    <gl-button v-gl-modal-directive="$options.modalId" data-testid="show-modal-button">
      {{ $options.i18n.instructions }}
    </gl-button>
    <gl-modal
      :modal-id="$options.modalId"
      :title="$options.i18n.installARunner"
      :action-secondary="closeButton"
    >
      <gl-alert v-if="showAlert" variant="danger" @dismiss="toggleAlert(false)">
        {{ $options.i18n.genericError }}
      </gl-alert>
      <h5>{{ __('Environment') }}</h5>
      <gl-button-group class="gl-mb-5">
        <gl-button
          v-for="platform in runnerPlatforms"
          :key="platform.name"
          data-testid="platform-button"
          @click="selectPlatform(platform.name)"
        >
          {{ platform.humanReadableName }}
        </gl-button>
      </gl-button-group>
      <template v-if="isPlatformSelected">
        <h5>
          {{ $options.i18n.architecture }}
        </h5>
        <gl-dropdown class="gl-mb-5" :text="selectedArchitecture.name">
          <gl-dropdown-item
            v-for="architecture in selectedPlatformArchitectures"
            :key="architecture.name"
            data-testid="architecture-dropdown-item"
            @click="selectArchitecture(architecture.name)"
          >
            {{ architecture.name }}
          </gl-dropdown-item>
        </gl-dropdown>
        <div class="gl-display-flex gl-align-items-center gl-mb-5">
          <h5>{{ $options.i18n.downloadInstallBinary }}</h5>
          <gl-button
            class="gl-ml-auto"
            :href="selectedArchitecture.downloadLocation"
            download
            data-testid="binary-download-button"
          >
            {{ $options.i18n.downloadLatestBinary }}
          </gl-button>
        </div>
      </template>
      <template v-if="!instructionsEmpty">
        <div class="gl-display-flex">
          <pre class="bg-light gl-flex-fill-1" data-testid="binary-instructions">
            {{ instructions.installInstructions }}
          </pre>
          <gl-button
            class="gl-align-self-start gl-ml-2 gl-mt-2"
            category="tertiary"
            variant="link"
            :data-clipboard-text="instructions.installationInstructions"
          >
            <gl-icon name="copy-to-clipboard" />
          </gl-button>
        </div>

        <hr />
        <h5 class="gl-mb-5">{{ $options.i18n.registerRunner }}</h5>
        <h5 class="gl-mb-5">{{ $options.i18n.method }}</h5>
        <div class="gl-display-flex">
          <pre class="bg-light gl-flex-fill-1" data-testid="runner-instructions">
            {{ instructions.registerInstructions }}
          </pre>
          <gl-button
            class="gl-align-self-start gl-ml-2 gl-mt-2"
            category="tertiary"
            variant="link"
            :data-clipboard-text="instructions.registerInstructions"
          >
            <gl-icon name="copy-to-clipboard" />
          </gl-button>
        </div>
      </template>
    </gl-modal>
  </div>
</template>
