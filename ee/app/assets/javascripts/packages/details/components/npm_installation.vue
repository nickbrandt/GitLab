<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import Tracking from '~/tracking';
import { TrackingActions, TrackingLabels } from '../constants';

export default {
  name: 'NpmInstallation',
  components: {
    CodeInstruction,
    GlTab,
    GlTabs,
  },
  mixins: [
    Tracking.mixin({
      label: TrackingLabels.NPM_INSTALLATION,
    }),
  ],
  props: {
    name: {
      type: String,
      required: true,
    },
    registryUrl: {
      type: String,
      required: true,
    },
    helpUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    packageRegistryUrl() {
      if (this.registryUrl.indexOf('package_name') > -1) {
        return this.registryUrl.substring(0, this.registryUrl.lastIndexOf('package_name'));
      }

      return this.registryUrl;
    },
    npmScope() {
      return this.name.substring(0, this.name.indexOf('/'));
    },
    npmCommand() {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `npm i ${this.name}`;
    },
    npmSetupCommand() {
      return `echo ${this.npmScope}:registry=${this.packageRegistryUrl} >> .npmrc`;
    },
    yarnCommand() {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `yarn add ${this.name}`;
    },
    yarnSetupCommand() {
      return `echo \\"${this.npmScope}:registry\\" \\"${this.packageRegistryUrl}\\" >> .yarnrc`;
    },
    helpText() {
      return sprintf(
        s__(
          `PackageRegistry|You may also need to setup authentication using an auth token.  %{linkStart}See
          the documentation%{linkEnd} to find out more.`,
        ),
        {
          linkStart: `<a href="${this.helpUrl}" target="_blank">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
  },
  methods: {
    onTabChanged(tabIndex) {
      const action = tabIndex === 0 ? TrackingActions.INSTALLATION : TrackingActions.REGISTRY_SETUP;
      this.track(action);
    },
  },
  trackingActions: { ...TrackingActions },
};
</script>

<template>
  <div class="append-bottom-default">
    <gl-tabs @input="onTabChanged">
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
            :instruction="npmSetupCommand"
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

          <p v-html="helpText"></p>
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
