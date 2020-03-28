<script>
import { GlLink, GlSprintf, GlTab, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import Tracking from '~/tracking';
import { NpmManager, TrackingActions, TrackingLabels } from '../constants';
import { trackInstallationTabChange } from '../utils';
import { mapGetters, mapState } from 'vuex';

export default {
  name: 'NpmInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
    GlTab,
    GlTabs,
  },
  mixins: [
    Tracking.mixin({
      label: TrackingLabels.NPM_INSTALLATION,
    }),
    trackInstallationTabChange,
  ],
  computed: {
    ...mapState(['npmHelpPath']),
    ...mapGetters(['npmInstallationCommand', 'npmSetupCommand']),
    npmCommand() {
      return this.npmInstallationCommand(NpmManager.NPM);
    },
    npmSetup() {
      return this.npmSetupCommand(NpmManager.NPM);
    },
    yarnCommand() {
      return this.npmInstallationCommand(NpmManager.YARN);
    },
    yarnSetupCommand() {
      return this.npmSetupCommand(NpmManager.YARN);
    },
  },
  i18n: {
    helpText: s__(
      'PackageRegistry|You may also need to setup authentication using an auth token. %{linkStart}See the documentation%{linkEnd} to find out more.',
    ),
  },
  trackingActions: { ...TrackingActions },
};
</script>

<template>
  <div class="append-bottom-default">
    <gl-tabs @input="trackInstallationTabChange">
      <gl-tab :title="s__('PackageRegistry|Installation')" title-item-class="js-installation-tab">
        <div class="prepend-left-default append-right-default">
          <p class="prepend-top-8 font-weight-bold">{{ s__('PackageRegistry|npm') }}</p>
          <code-instruction
            :instruction="npmCommand"
            :copy-text="s__('PackageRegistry|Copy npm command')"
            class="js-npm-install"
            :tracking-action="$options.trackingActions.COPY_NPM_INSTALL_COMMAND"
          />

          <p class="prepend-top-default font-weight-bold">{{ s__('PackageRegistry|yarn') }}</p>
          <code-instruction
            :instruction="yarnCommand"
            :copy-text="s__('PackageRegistry|Copy yarn command')"
            class="js-yarn-install"
            :tracking-action="$options.trackingActions.COPY_YARN_INSTALL_COMMAND"
          />
        </div>
      </gl-tab>
      <gl-tab :title="s__('PackageRegistry|Registry Setup')" title-item-class="js-setup-tab">
        <div class="prepend-left-default append-right-default">
          <p class="prepend-top-8 font-weight-bold">{{ s__('PackageRegistry|npm') }}</p>
          <code-instruction
            :instruction="npmSetup"
            :copy-text="s__('PackageRegistry|Copy npm setup command')"
            class="js-npm-setup"
            :tracking-action="$options.trackingActions.COPY_NPM_SETUP_COMMAND"
          />

          <p class="prepend-top-default font-weight-bold">{{ s__('PackageRegistry|yarn') }}</p>
          <code-instruction
            :instruction="yarnSetupCommand"
            :copy-text="s__('PackageRegistry|Copy yarn setup command')"
            class="js-yarn-setup"
            :tracking-action="$options.trackingActions.COPY_YARN_SETUP_COMMAND"
          />

          <gl-sprintf :message="$options.i18n.helpText">
            <template #link="{ content }">
              <gl-link :href="npmHelpPath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
