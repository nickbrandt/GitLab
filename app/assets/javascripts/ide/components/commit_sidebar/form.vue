<script>
import { createNamespacedHelpers, mapActions, mapGetters, mapState } from 'vuex';
import { __, sprintf } from '~/locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import CommitMessageField from './message_field.vue';
import Actions from './actions.vue';
import SuccessMessage from './success_message.vue';
import { leftSidebarViews, MAX_WINDOW_HEIGHT_COMPACT } from '../../constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const {
  mapState: mapCommitState,
  mapActions: mapCommitActions,
  mapGetters: mapCommitGetters,
} = createNamespacedHelpers('commit');

export default {
  components: {
    Actions,
    LoadingButton,
    CommitMessageField,
    SuccessMessage,
  },
  mixins: [glFeatureFlagsMixin()],
  data() {
    return {
      isCompact: true,
      componentHeight: null,
    };
  },
  computed: {
    ...mapState(['changedFiles', 'stagedFiles', 'lastCommitMsg']),
    ...mapState('leftPane', {
      leftPaneCurrentView: 'currentView',
    }),
    ...mapCommitState(['commitMessage', 'submitCommitLoading']),
    ...mapGetters(['hasChanges']),
    ...mapCommitGetters(['discardDraftButtonDisabled', 'preBuiltCommitMessage']),
    overviewText() {
      return sprintf(
        this.glFeatures.stageAllByDefault
          ? __(
              '<strong>%{stagedFilesLength} staged</strong> and <strong>%{changedFilesLength} unstaged</strong> changes',
            )
          : __(
              '<strong>%{changedFilesLength} unstaged</strong> and <strong>%{stagedFilesLength} staged</strong> changes',
            ),
        {
          stagedFilesLength: this.stagedFiles.length,
          changedFilesLength: this.changedFiles.length,
        },
      );
    },
    commitButtonText() {
      return this.stagedFiles.length ? __('Commit') : __('Stage & Commit');
    },

    leftPaneCurrentViewIsCommitView() {
      return this.leftPaneCurrentView === leftSidebarViews.commit.name;
    },
  },
  watch: {
    leftPaneCurrentView() {
      if (this.lastCommitMsg) {
        this.isCompact = false;
      } else {
        this.isCompact = !(
          this.leftPaneCurrentViewIsCommitView && window.innerHeight >= MAX_WINDOW_HEIGHT_COMPACT
        );
      }
    },
    lastCommitMsg() {
      this.isCompact = !this.leftPaneCurrentViewIsCommitView && this.lastCommitMsg === '';
    },
  },
  mounted: function mounted() {
    if (this.lastCommitMsg) {
      this.isCompact = false;
    }
  },
  methods: {
    ...mapActions('leftPane', ['open', 'currentView']),
    ...mapCommitActions(['updateCommitMessage', 'discardDraft', 'commitChanges']),
    toggleIsCompact() {
      if (this.leftPaneCurrentViewIsCommitView) {
        this.isCompact = !this.isCompact;
      } else {
        this.open(leftSidebarViews.commit)
          .then(() => {
            this.isCompact = false;
          })
          .catch(e => {
            throw e;
          });
      }
    },
    beforeEnterTransition() {
      const elHeight = this.isCompact
        ? this.$refs.formEl && this.$refs.formEl.offsetHeight
        : this.$refs.compactEl && this.$refs.compactEl.offsetHeight;

      this.componentHeight = elHeight;
    },
    enterTransition() {
      this.$nextTick(() => {
        const elHeight = this.isCompact
          ? this.$refs.compactEl && this.$refs.compactEl.offsetHeight
          : this.$refs.formEl && this.$refs.formEl.offsetHeight;

        this.componentHeight = elHeight;
      });
    },
    afterEndTransition() {
      this.componentHeight = null;
    },
  },
  leftSidebarViews,
};
</script>

<template>
  <div
    :class="{
      'is-compact': isCompact,
      'is-full': !isCompact,
    }"
    :style="{
      height: componentHeight ? `${componentHeight}px` : null,
    }"
    class="multi-file-commit-form"
  >
    <transition
      name="commit-form-slide-up"
      @before-enter="beforeEnterTransition"
      @enter="enterTransition"
      @after-enter="afterEndTransition"
    >
      <div v-if="isCompact" ref="compactEl" class="commit-form-compact">
        <button
          :disabled="!hasChanges"
          type="button"
          class="btn btn-primary btn-sm btn-block qa-begin-commit-button"
          @click="toggleIsCompact"
        >
          {{ __('Commit…') }}
        </button>
        <p class="text-center" v-html="overviewText"></p>
      </div>
      <form v-if="!isCompact" ref="formEl" @submit.prevent.stop="commitChanges">
        <transition name="fade"> <success-message v-show="lastCommitMsg" /> </transition>
        <commit-message-field
          :text="commitMessage"
          :placeholder="preBuiltCommitMessage"
          @input="updateCommitMessage"
          @submit="commitChanges"
        />
        <div class="clearfix prepend-top-15">
          <actions />
          <loading-button
            :loading="submitCommitLoading"
            :label="commitButtonText"
            container-class="btn btn-success btn-sm float-left qa-commit-button"
            @click="commitChanges"
          />
          <button
            v-if="!discardDraftButtonDisabled"
            type="button"
            class="btn btn-default btn-sm float-right"
            @click="discardDraft"
          >
            {{ __('Discard draft') }}
          </button>
          <button
            v-else
            type="button"
            class="btn btn-default btn-sm float-right"
            @click="toggleIsCompact"
          >
            {{ __('Collapse') }}
          </button>
        </div>
      </form>
    </transition>
  </div>
</template>
