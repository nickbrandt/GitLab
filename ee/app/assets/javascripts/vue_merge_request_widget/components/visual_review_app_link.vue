<script>
import Icon from '~/vue_shared/components/icon.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    GlButton,
    GlModal,
    Icon,
    ModalCopyButton,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  props: {
    appMetadata: {
      type: Object,
      required: true,
    },
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
    link: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      modalId: 'visual-review-app-info',
    };
  },
  computed: {
    copyToClipboard() {
      return {
        script: s__('VisualReviewApp|Copy script'),
        mrId: s__('VisualReviewApp|Copy merge request ID'),
      };
    },
    copyString() {
      /* eslint-disable no-useless-escape */
      return {
        script: `<script defer
  data-project-id='${this.appMetadata.sourceProjectId}'
  data-project-path='${this.appMetadata.sourceProjectPath}'
  <!-- Remove the following line to use the same script for multiple merge requests -->
  data-merge-request-id='${this.appMetadata.mergeRequestId}'
  data-mr-url='${this.appMetadata.appUrl}'
  id='review-app-toolbar-script'
  src='https://gitlab.com/assets/webpack/visual_review_toolbar.js'><\/script>`,
      };
      /* eslint-enable no-useless-escape */
    },
    instructionText() {
      return {
        intro: {
          p1: s__(
            'VisualReviewApp|Follow the steps below to enable Visual Reviews inside your application.',
          ),
          p2: s__(
            'VisualReviewApp|Steps 1 and 2 (and sometimes 3) are performed once by the developer before requesting feedback. Steps 3 (if necessary), 4, and 5 are performed by the reviewer each time they perform a review.',
          ),
        },
        step1: sprintf(
          s__('VisualReviewApp|%{stepStart}Step 1%{stepEnd}. Copy the following script:'),
          {
            stepStart: '<strong>',
            stepEnd: '</strong>',
          },
          false,
        ),
        step2: sprintf(
          s__(
            'VisualReviewApp|%{stepStart}Step 2%{stepEnd}. Add it to the %{headTags} tags of every page of your application, ensuring the merge request ID is set or not set as required. ',
          ),
          {
            stepStart: '<strong>',
            stepEnd: '</strong>',
            headTags: `<code>&lt;head&gt;</code>`,
          },
          false,
        ),
        step3: sprintf(
          s__(
            `VisualReviewApp|%{stepStart}Step 3%{stepEnd}. If not previously %{linkStart}configured%{linkEnd} by a developer, enter the merge request ID for the review when prompted. The ID of this merge request is %{stepStart}%{mrId}%{stepStart}.`,
          ),
          {
            stepStart: '<strong>',
            stepEnd: '</strong>',
            linkStart:
              '<a href="https://docs.gitlab.com/ee/ci/review_apps/#configuring-visual-reviews">',
            linkEnd: '</a>',
            mrId: this.appMetadata.mergeRequestId,
          },
          false,
        ),
        step4: sprintf(
          s__('VisualReviewApp|%{stepStart}Step 4%{stepEnd}. Leave feedback in the Review App.'),
          {
            stepStart: '<strong>',
            stepEnd: '</strong>',
          },
          false,
        ),
      };
    },
    modalTitle() {
      return s__('VisualReviewApp|Enable Visual Reviews');
    },
  },
};
</script>
<template>
  <div class="inline">
    <gl-button
      v-gl-modal="modalId"
      class="btn btn-default btn-sm prepend-left-8 js-review-button"
      :class="cssClass"
      type="button"
    >
      {{ s__('VisualReviewApp|Review') }}
    </gl-button>
    <gl-modal
      :modal-id="modalId"
      :title="modalTitle"
      size="lg"
      class="text-2 ws-normal"
      ok-variant="success"
    >
      <template slot="modal-ok">
        <a
          :href="link"
          target="_blank"
          rel="noopener noreferrer nofollow"
          class="text-white js-review-app-link"
          data-track-event="open_review_app"
          data-track-label="review_app"
        >
          {{ s__('VisualReviewApp|Open review app') }}
          <icon class="fwhite" name="external-link" />
        </a>
      </template>
      <p v-html="instructionText.intro.p1"></p>
      <p v-html="instructionText.intro.p2"></p>
      <div>
        <p v-html="instructionText.step1"></p>
        <div class="flex align-items-start">
          <pre> {{ copyString.script }} </pre>
          <modal-copy-button
            :title="copyToClipboard.script"
            :text="copyString.script"
            :modal-id="modalId"
            css-classes="border-0"
          />
        </div>
      </div>
      <p v-html="instructionText.step2"></p>
      <p>
        <span v-html="instructionText.step3"></span>
        <modal-copy-button
          :title="copyToClipboard.mrId"
          :text="appMetadata.mergeRequestId.toString()"
          :modal-id="modalId"
          css-classes="border-0 gl-pt-0 gl-pr-0 gl-pl-1 gl-pb-0"
        />
      </p>
      <p v-html="instructionText.step4"></p>
    </gl-modal>
  </div>
</template>
