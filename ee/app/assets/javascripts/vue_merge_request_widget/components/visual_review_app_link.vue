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
    copyString() {
      /* eslint-disable no-useless-escape */
      return {
        script: `<script defer
  data-project-id='${this.appMetadata.sourceProjectId}'
  data-project-path='${this.appMetadata.sourceProjectPath}'
  data-merge-request-id='${this.appMetadata.mergeRequestId}'
  data-mr-url='${this.appMetadata.appUrl}'
  id='review-app-toolbar-script'
  src='https://gitlab.com/assets/webpack/visual_review_toolbar.js'><\/script>`,
      };
      /* eslint-enable no-useless-escape */
    },
    instructionText() {
      return {
        intro: s__(
          'VisualReviewApp|Adding the following script to your code makes it possible to directly leave feedback inside of the review app. Feedback given will get submitted automatically to this merge request’s discussion, including metadata.',
        ),
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
            'VisualReviewApp|%{stepStart}Step 2%{stepEnd}. Add it to the %{headTags} of every page of your application. ',
          ),
          {
            stepStart: '<strong>',
            stepEnd: '</strong>',
            headTags: `<code>&lt;head&gt;&lt;/head&gt;</code>`,
          },
          false,
        ),
        step3: sprintf(
          s__(
            'VisualReviewApp|%{stepStart}Step 3%{stepEnd}. Open the review app and provide a personal access token following %{linkStart}personal access token%{linkEnd}.',
          ),
          {
            stepStart: '<strong>',
            stepEnd: '</strong>',
            linkStart:
              '<a href="https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html">',
            linkEnd: '</a>',
          },
          false,
        ),
        step4: sprintf(
          s__(
            'VisualReviewApp|%{stepStart}Step 4%{stepEnd}. You are now able to leave feedback from within the review app.',
          ),
          {
            stepStart: '<strong>',
            stepEnd: '</strong>',
          },
          false,
        ),
      };
    },
    modalTitle() {
      return s__('VisualReviewApp|Review and give feedback directly from within the review app');
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
        <a :href="link" target="_blank" rel="noopener noreferrer nofollow" class="text-white">
          {{ s__('VisualReviewApp|Open review app') }}
          <icon css-classes="fwhite" name="external-link" />
        </a>
      </template>
      <p v-html="instructionText.intro"></p>
      <div>
        <p v-html="instructionText.step1"></p>
        <div class="flex align-items-start">
          <pre> {{ copyString.script }} </pre>
          <modal-copy-button
            title="Copy script"
            :text="copyString.script"
            :modal-id="modalId"
            css-classes="border-0"
          />
        </div>
      </div>
      <p v-html="instructionText.step2"></p>
      <p v-html="instructionText.step3"></p>
      <p v-html="instructionText.step4"></p>
    </gl-modal>
  </div>
</template>
