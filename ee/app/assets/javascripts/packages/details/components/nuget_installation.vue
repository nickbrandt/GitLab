<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import Tracking from '~/tracking';
import { TrackingActions, TrackingLabels } from '../constants';
import { trackInstallationTabChange } from '../utils';

export default {
  name: 'NugetInstallation',
  components: {
    CodeInstruction,
    GlTab,
    GlTabs,
  },
  mixins: [
    Tracking.mixin({
      label: TrackingLabels.NUGET_INSTALLATION,
    }),
    trackInstallationTabChange,
  ],
  props: {
    packageEntity: {
      type: Object,
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
    nugetCommand() {
      return `nuget install ${this.packageEntity.name} -Source "GitLab"`;
    },
    setupCommand() {
      return `nuget source Add -Name "GitLab" -Source "${this.registryUrl}" -UserName <your_username> -Password <your_token>`;
    },
    helpText() {
      return sprintf(
        s__(
          `PackageRegistry|For more information on the NuGet registry, %{linkStart}see the documentation%{linkEnd}.`,
        ),
        {
          linkStart: `<a href="${this.helpUrl}" target="_blank" rel="noopener noreferer">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
  },
  trackingActions: { ...TrackingActions },
};
</script>

<template>
  <div class="append-bottom-default">
    <gl-tabs @input="trackInstallationTabChange">
      <gl-tab :title="s__('PackageRegistry|Installation')" title-item-class="js-installation-tab">
        <div class="prepend-left-default append-right-default">
          <p class="prepend-top-8 font-weight-bold">{{ s__('PackageRegistry|NuGet Command') }}</p>
          <code-instruction
            :instruction="nugetCommand"
            :copy-text="s__('PackageRegistry|Copy NuGet Command')"
            class="js-nuget-command"
            :tracking-action="$options.trackingActions.COPY_NUGET_INSTALL_COMMAND"
          />
        </div>
      </gl-tab>
      <gl-tab :title="s__('PackageRegistry|Registry Setup')" title-item-class="js-setup-tab">
        <div class="prepend-left-default append-right-default">
          <p class="prepend-top-8 font-weight-bold">
            {{ s__('PackageRegistry|Add NuGet Source') }}
          </p>
          <code-instruction
            :instruction="setupCommand"
            :copy-text="s__('PackageRegistry|Copy NuGet Setup Command')"
            class="js-nuget-setup"
            :tracking-action="$options.trackingActions.COPY_NUGET_SETUP_COMMAND"
          />
          <p v-html="helpText"></p>
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
