<script>
import { GlLink, GlSprintf, GlTab, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import Tracking from '~/tracking';
import { TrackingActions, TrackingLabels } from '../constants';
import { trackInstallationTabChange } from '../utils';
import { mapGetters, mapState } from 'vuex';

export default {
  name: 'NugetInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
    GlTab,
    GlTabs,
  },
  mixins: [
    Tracking.mixin({
      label: TrackingLabels.NUGET_INSTALLATION,
    }),
    trackInstallationTabChange,
  ],
  computed: {
    ...mapState(['nugetHelpPath']),
    ...mapGetters(['nugetInstallationCommand', 'nugetSetupCommand']),
  },
  i18n: {
    helpText: s__(
      'PackageRegistry|For more information on the NuGet registry, %{linkStart}see the documentation%{linkEnd}.',
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
          <p class="prepend-top-8 font-weight-bold">{{ s__('PackageRegistry|NuGet Command') }}</p>
          <code-instruction
            :instruction="nugetInstallationCommand"
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
            :instruction="nugetSetupCommand"
            :copy-text="s__('PackageRegistry|Copy NuGet Setup Command')"
            class="js-nuget-setup"
            :tracking-action="$options.trackingActions.COPY_NUGET_SETUP_COMMAND"
          />
          <gl-sprintf :message="$options.i18n.helpText">
            <template #link="{ content }">
              <gl-link :href="nugetHelpPath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
