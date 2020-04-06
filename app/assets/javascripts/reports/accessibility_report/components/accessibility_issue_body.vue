<script>
export default {
  name: 'AccessibilityIssueBody',
  props: {
    issue: {
      type: Object,
      required: true,
    },
    isNew: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    parsedTECHSCode() {
      /*
       * In issue code looks like "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail"
       * or "WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent"
       *
       * The TECHS code is the "G18" or "H91" from the code which is used for the documentation.
       * This regex pattern simply gets the part of the string where there is a single letter
       * followed by two digits.
       */
      return this.issue.code.match(/[A-Z]{1}[1-9]{2}/g)[0];
    },
    learnMoreUrl() {
      return `https://www.w3.org/TR/WCAG20-TECHS/${this.parsedTECHSCode}.html`;
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text">
      <div
        v-if="isNew"
        ref="accessibility-issue-is-new-badge"
        class="badge badge-danger append-right-5"
      >
        {{ __('New') }}
      </div>
      {{ issue.name }}
      <a ref="accessibility-issue-learn-more" :href="learnMoreUrl">{{ __('Learn More') }}</a>
      {{ __('Message: ') }}
      {{ issue.message }}
    </div>
  </div>
</template>
