import $ from 'jquery';
import Vue from 'vue';
import collapseIcon from 'ee/boards/icons/fullscreen_collapse.svg';
import expandIcon from 'ee/boards/icons/fullscreen_expand.svg';

export default (ModalStore, boardsStore, $boardApp) => {
  const issueBoardsContent = document.querySelector('.content-wrapper > .js-focus-mode-board');

  return new Vue({
    el: document.getElementById('js-toggle-focus-btn'),
    data: {
      modal: ModalStore.store,
      store: boardsStore.state,
      isFullscreen: false,
      focusModeAvailable: $boardApp.hasAttribute('data-focus-mode-available'),
    },
    methods: {
      toggleFocusMode() {
        if (!this.focusModeAvailable) {
          return;
        }

        $(this.$refs.toggleFocusModeButton).tooltip('hide');
        issueBoardsContent.classList.toggle('is-focused');

        this.isFullscreen = !this.isFullscreen;
      },
    },
    template: `
      <div class="board-extra-actions">
        <a
          href="#"
          class="btn btn-default has-tooltip prepend-left-10 js-focus-mode-btn"
          role="button"
          aria-label="Toggle focus mode"
          title="Toggle focus mode"
          ref="toggleFocusModeButton"
          v-if="focusModeAvailable"
          @click="toggleFocusMode">
          <span v-show="isFullscreen">
            ${collapseIcon}
          </span>
          <span v-show="!isFullscreen">
            ${expandIcon}
          </span>
        </a>
      </div>
    `,
  });
};
