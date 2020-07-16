<script>
import { GlModal, GlIcon, GlSprintf } from '@gitlab/ui';
import { n__, __ } from '~/locale';

export default {
  components: { GlModal, GlIcon, GlSprintf },
  props: {
    scannedUrls: {
      required: true,
      type: Array,
    },
    scannedResourcesCount: {
      required: true,
      type: Number,
    },
    downloadLink: {
      required: true,
      type: String,
    },
  },
  modal: {
    modalId: 'dastUrl',
    actionPrimary: {
      text: __('Close'),
      attributes: { variant: 'success' },
    },
  },
  computed: {
    title() {
      return n__('%d Scanned URL', '%d Scanned URLs', this.scannedResourcesCount);
    },
    limitedScannedUrls() {
      // show only 15 scanned urls
      return this.scannedUrls.slice(0, 15);
    },
    downloadButton() {
      const buttonAttrs = {
        text: __('Download as CSV'),
        attributes: {
          variant: 'success',
          class: 'btn-secondary gl-button',
          href: this.downloadLink,
          download: true,
          'data-testid': 'download-button',
        },
      };
      return this.downloadLink ? buttonAttrs : null;
    },
  },
};
</script>
<template>
  <gl-modal
    :title="title"
    title-tag="h5"
    v-bind="$options.modal"
    :action-secondary="downloadButton"
  >
    <div class="gl-px-3">
      <!-- heading -->
      <div class="gl-display-flex gl-text-gray-600">
        <div class="gl-w-11">{{ __('Method') }}</div>
        <div class="gl-flex-fill-1">{{ __('URL') }}</div>
      </div>
      <hr class="gl-my-3" />

      <!-- rows -->
      <div v-for="(url, index) in limitedScannedUrls" :key="index" class="gl-display-flex gl-my-2">
        <div class="gl-w-11">{{ url.requestMethod.toUpperCase() }}</div>
        <div
          class="gl-flex-fill-1 gl-overflow-hidden gl-white-space-nowrap gl-text-overflow-ellipsis"
          data-testid="dast-scanned-url"
        >
          {{ url.url }}
        </div>
      </div>

      <!-- banner -->
      <div
        v-if="downloadLink"
        class="gl-display-inline-block gl-bg-gray-50 gl-my-3 gl-pl-3 gl-pr-7 gl-py-5"
      >
        <gl-icon name="bulb" class="gl-vertical-align-middle gl-mr-5" />
        <b class="gl-vertical-align-middle">
          <gl-sprintf
            :message="
              __('To view all %{scannedResourcesCount} scanned URLs, please download the CSV file')
            "
          >
            <template #scannedResourcesCount>
              {{ scannedResourcesCount }}
            </template>
          </gl-sprintf>
        </b>
      </div>
    </div>
  </gl-modal>
</template>
