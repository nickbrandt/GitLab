<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import Tracking from '~/tracking';
import { TrackingActions, TrackingLabels } from '../constants';
import trackInstallationTabChange from '../utils';

export default {
  name: 'MavenInstallation',
  components: {
    CodeInstruction,
    GlTab,
    GlTabs,
  },
  mixins: [
    Tracking.mixin({
      label: TrackingLabels.MAVEN_INSTALLATION,
    }),
    trackInstallationTabChange,
  ],
  props: {
    heading: {
      type: String,
      default: s__('PackageRegistry|Package installation'),
      required: false,
    },
    mavenMetadata: {
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
    mavenData() {
      const {
        app_group: appGroup = '',
        app_name: appName = '',
        app_version: appVersion = '',
      } = this.mavenMetadata;

      return {
        appGroup,
        appName,
        appVersion,
      };
    },
    mavenXml() {
      return `<dependency>
  <groupId>${this.mavenData.appGroup}</groupId>
  <artifactId>${this.mavenData.appName}</artifactId>
  <version>${this.mavenData.appVersion}</version>
</dependency>`;
    },
    mavenCommand() {
      const { appGroup: group, appName: name, appVersion: version } = this.mavenData;

      return `mvn dependency:get -Dartifact=${group}:${name}:${version}`;
    },
    mavenSetupXml() {
      return `<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>${this.registryUrl}</url>
  </repository>
</repositories>

<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>${this.registryUrl}</url>
  </repository>

  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>${this.registryUrl}</url>
  </snapshotRepository>
</distributionManagement>`;
    },
    helpText() {
      return sprintf(
        s__(
          `PackageRegistry|For more information on the Maven registry, %{linkStart}see the documentation%{linkEnd}.`,
        ),
        {
          linkStart: `<a href="${this.helpUrl}" target="_blank" rel="noopener noreferer">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
  },
  i18n: {
    xmlText: sprintf(
      s__(
        `PackageRegistry|Copy and paste this inside your %{codeStart}pom.xml%{codeEnd} %{codeStart}dependencies%{codeEnd} block.`,
      ),
      {
        codeStart: `<code>`,
        codeEnd: '</code>',
      },
      false,
    ),
    setupText: sprintf(
      s__(
        `PackageRegistry|If you haven't already done so, you will need to add the below to your %{codeStart}pom.xml%{codeEnd} file.`,
      ),
      {
        codeStart: `<code>`,
        codeEnd: '</code>',
      },
      false,
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
          <p class="prepend-top-8 font-weight-bold">{{ s__('PackageRegistry|Maven XML') }}</p>
          <p v-html="$options.i18n.xmlText"></p>
          <code-instruction
            :instruction="mavenXml"
            :copy-text="s__('PackageRegistry|Copy Maven XML')"
            class="js-maven-xml"
            multiline
            :tracking-action="$options.trackingActions.COPY_MAVEN_XML"
          />

          <p class="prepend-top-default font-weight-bold">
            {{ s__('PackageRegistry|Maven Command') }}
          </p>
          <code-instruction
            :instruction="mavenCommand"
            :copy-text="s__('PackageRegistry|Copy Maven command')"
            class="js-maven-command"
            :tracking-action="$options.trackingActions.COPY_MAVEN_COMMAND"
          />
        </div>
      </gl-tab>
      <gl-tab :title="s__('PackageRegistry|Registry Setup')" title-item-class="js-setup-tab">
        <div class="prepend-left-default append-right-default">
          <p v-html="$options.i18n.setupText"></p>
          <code-instruction
            :instruction="mavenSetupXml"
            :copy-text="s__('PackageRegistry|Copy Maven registry XML')"
            class="js-maven-setup-xml"
            multiline
            :tracking-action="$options.trackingActions.COPY_MAVEN_SETUP"
          />
          <p v-html="helpText"></p>
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
