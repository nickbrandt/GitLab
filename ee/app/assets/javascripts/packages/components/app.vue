<script>
import {
  GlButton,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlLink,
  GlEmptyState,
} from '@gitlab/ui';
import _ from 'underscore';
import PackageInformation from './information.vue';
import Icon from '~/vue_shared/components/icon.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { formatDate } from '~/lib/utils/datetime_utility';
import { s__, sprintf } from '~/locale';
import PackageType from '../constants';

export default {
  name: 'PackagesApp',
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlModal,
    Icon,
    PackageInformation,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [timeagoMixin],
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
    files: {
      type: Array,
      default: () => [],
      required: true,
    },
    canDelete: {
      type: Boolean,
      default: false,
      required: true,
    },
    destroyPath: {
      type: String,
      default: '',
      required: true,
    },
    emptySvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    isValidPackage() {
      if (this.packageEntity.name) {
        return true;
      }

      return false;
    },
    canDeletePackage() {
      return this.canDelete && this.destroyPath;
    },
    deleteModalDescription() {
      return sprintf(
        s__(
          `PackageRegistry|You are about to delete version %{boldStart}%{version}%{boldEnd} of %{boldStart}%{name}%{boldEnd}. Are you sure?`,
        ),
        {
          version: _.escape(this.packageEntity.version),
          name: _.escape(this.packageEntity.name),
          boldStart: '<b>',
          boldEnd: '</b>',
        },
        false,
      );
    },
    packageInformation() {
      return [
        {
          label: s__('Name'),
          value: this.packageEntity.name,
        },
        {
          label: s__('Version'),
          value: this.packageEntity.version,
        },
        {
          label: s__('Created on'),
          value: formatDate(this.packageEntity.created_at),
        },
      ];
    },
    packageMetadataTitle() {
      switch (this.packageEntity.package_type) {
        case PackageType.MAVEN:
          return s__('Maven Metadata');
        default:
          return s__('Package information');
      }
    },
    packageMetadata() {
      switch (this.packageEntity.package_type) {
        case PackageType.MAVEN:
          return [
            {
              label: s__('Group ID'),
              value: this.packageEntity.maven_metadatum.app_group,
            },
            {
              label: s__('Artifact ID'),
              value: this.packageEntity.maven_metadatum.app_name,
            },
            {
              label: s__('Version'),
              value: this.packageEntity.maven_metadatum.app_version,
            },
          ];
        default:
          return null;
      }
    },
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
    cancelDelete() {
      this.$refs.deleteModal.hide();
    },
  },
  i18n: {
    deleteModalTitle: s__(`PackageRegistry|Delete Package Version`),
  },
};
</script>

<template>
  <gl-empty-state
    v-if="!isValidPackage"
    :title="s__('PackageRegistry|Unable to load package')"
    :description="s__('PackageRegistry|There was a problem fetching the details for this package.')"
    :svg-path="emptySvgPath"
    class="js-package-empty-state"
  />

  <div v-else class="packages-app">
    <div class="detail-page-header d-flex justify-content-between">
      <strong class="js-version-title">{{ packageEntity.version }}</strong>
      <gl-button
        v-if="canDeletePackage"
        v-gl-modal="'delete-modal'"
        class="js-delete-button"
        variant="danger"
        >{{ __('Delete') }}</gl-button
      >
    </div>

    <div class="row prepend-top-default">
      <package-information :type="packageEntity.package_type" :information="packageInformation" />
      <package-information
        v-if="packageMetadata"
        :heading="packageMetadataTitle"
        :information="packageMetadata"
      />
    </div>

    <table class="table">
      <thead>
        <tr>
          <th>{{ __('Name') }}</th>
          <th>{{ __('Size') }}</th>
          <th>
            <span class="pull-right">{{ __('Created') }}</span>
          </th>
        </tr>
      </thead>

      <tbody>
        <tr v-for="file in files" :key="file.id" class="js-file-row">
          <td class="d-flex align-items-center">
            <icon name="doc-code" class="space-right" /><gl-link
              :href="file.download_path"
              class="js-file-download"
              >{{ file.file_name }}</gl-link
            >
          </td>
          <td>{{ formatSize(file.size) }}</td>
          <td>
            <span v-gl-tooltip class="pull-right" :title="tooltipTitle(file.created_at)">{{
              timeFormated(file.created_at)
            }}</span>
          </td>
        </tr>
      </tbody>
    </table>

    <gl-modal ref="deleteModal" class="js-delete-modal" modal-id="delete-modal">
      <template v-slot:modal-title>{{ $options.i18n.deleteModalTitle }}</template>
      <p v-html="deleteModalDescription"></p>

      <div slot="modal-footer" class="w-100">
        <div class="float-right">
          <gl-button @click="cancelDelete()">{{ __('Cancel') }}</gl-button>
          <gl-button data-method="delete" :to="destroyPath" variant="danger">{{
            __('Delete')
          }}</gl-button>
        </div>
      </div>
    </gl-modal>
  </div>
</template>
