import Vue from 'vue';
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlToggle } from '@gitlab/ui';
import Tracking from '~/tracking';
import store from '~/boards/stores';

export default () =>
  new Vue({
    el: document.getElementById('js-board-labels-toggle'),
    components: {
      GlToggle,
    },
    store,
    computed: {
      ...mapState(['isShowingLabels']),
      ...mapGetters(['getLabelToggleState']),
    },
    methods: {
      ...mapActions(['toggleShowLabels']),

      onToggle() {
        this.toggleShowLabels();

        Tracking.event(document.body.dataset.page, 'toggle', {
          label: 'show_labels',
          property: this.getLabelToggleState,
        });
      },
    },
    template: `
      <div class="board-labels-toggle-wrapper d-flex align-items-center prepend-left-10">
        <gl-toggle
          :value="isShowingLabels"
          label="Show labels"
          label-position="left"
          aria-describedby="board-labels-toggle-text"
          data-qa-selector="show_labels_toggle"
          @change="onToggle"
        />
      </div>
    `,
  });
