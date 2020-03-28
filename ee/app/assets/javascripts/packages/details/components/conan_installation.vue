<script>
import { GlLink, GlSprintf, GlTab, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import Tracking from '~/tracking';
import { TrackingActions, TrackingLabels } from '../constants';
import { trackInstallationTabChange } from '../utils';
import { mapGetters, mapState } from 'vuex';

export default {
  name: 'ConanInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
    GlTab,
    GlTabs,
  },
  mixins: [
    Tracking.mixin({
      label: TrackingLabels.CONAN_INSTALLATION,
    }),
    trackInstallationTabChange,
  ],
  computed: {
    ...mapState(['conanHelpPath']),
    ...mapGetters(['conanInstallationCommand', 'conanSetupCommand']),
  },
  i18n: {
    helpText: s__(
      'PackageRegistry|For more information on the Conan registry, %{linkStart}see the documentation%{linkEnd}.',
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
          <p class="prepend-top-8 font-weight-bold">{{ s__('PackageRegistry|Conan Command') }}</p>
          <code-instruction
            :instruction="conanInstallationCommand"
            :copy-text="s__('PackageRegistry|Copy Conan Command')"
            class="js-conan-command"
            :tracking-action="$options.trackingActions.COPY_CONAN_COMMAND"
          />
        </div>
      </gl-tab>
      <gl-tab :title="s__('PackageRegistry|Registry Setup')" title-item-class="js-setup-tab">
        <div class="prepend-left-default append-right-default">
          <p class="prepend-top-8 font-weight-bold">
            {{ s__('PackageRegistry|Add Conan Remote') }}
          </p>
          <code-instruction
            :instruction="conanSetupCommand"
            :copy-text="s__('PackageRegistry|Copy Conan Setup Command')"
            class="js-conan-setup"
            :tracking-action="$options.trackingActions.COPY_CONAN_SETUP_COMMAND"
          />
          <gl-sprintf :message="$options.i18n.helpText">
            <template #link="{ content }">
              <gl-link :href="conanHelpPath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
