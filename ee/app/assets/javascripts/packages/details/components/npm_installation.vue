<script>
import { s__, sprintf } from '~/locale';
import { GlTab, GlTabs } from '@gitlab/ui';
import CodeInstruction from './code_instruction.vue';

export default {
  name: 'NpmInstallation',
  components: {
    CodeInstruction,
    GlTab,
    GlTabs,
  },
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
};
</script>

<template>
  <div class="append-bottom-default">
    <gl-tabs>
      <gl-tab :title="s__('PackageRegistry|Installation')">
        <div class="prepend-left-default append-right-default">
          <p class="prepend-top-8 font-weight-bold">{{ s__('PackageRegistry|npm') }}</p>
          <code-instruction
            :instruction="npmCommand"
            :copy-text="s__('PackageRegistry|Copy npm command')"
            class="js-npm-install"
          />

          <p class="prepend-top-default font-weight-bold">{{ s__('PackageRegistry|yarn') }}</p>
          <code-instruction
            :instruction="yarnCommand"
            :copy-text="s__('PackageRegistry|Copy yarn command')"
            class="js-yarn-install"
          />
        </div>
      </gl-tab>
      <gl-tab :title="s__('PackageRegistry|Registry Setup')">
        <div class="prepend-left-default append-right-default">
          <p class="prepend-top-8 font-weight-bold">{{ s__('PackageRegistry|npm') }}</p>
          <code-instruction
            :instruction="npmSetupCommand"
            :copy-text="s__('PackageRegistry|Copy npm setup command')"
            class="js-npm-setup"
          />

          <p class="prepend-top-default font-weight-bold">{{ s__('PackageRegistry|yarn') }}</p>
          <code-instruction
            :instruction="yarnSetupCommand"
            :copy-text="s__('PackageRegistry|Copy yarn setup command')"
            class="js-yarn-setup"
          />

          <p v-html="helpText"></p>
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
