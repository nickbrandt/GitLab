import Vue from 'vue';
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlToggle } from '@gitlab/ui';
import { __ } from '~/locale';
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

      toggleOnLabel() {
        return __('Showing all labels');
      },
      toggleOffLabel() {
        return __('Hiding all labels');
      },
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
        <span id="board-labels-toggle-text" class="text-nowrap">
          {{ __('Show labels') }}
        </span>
        <gl-toggle
          :value="isShowingLabels"
          class="prepend-left-10 mb-0"
          :label-on="toggleOnLabel"
          :label-off="toggleOffLabel"
          aria-describedby="board-labels-toggle-text"
          data-qa-selector="show_labels_toggle"
          @change="onToggle"
        />
      </div>
    `,
  });
