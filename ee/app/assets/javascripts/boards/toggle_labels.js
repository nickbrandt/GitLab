import Vue from 'vue';
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlToggle } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import store from '~/boards/stores';

export default () =>
  new Vue({
    el: document.getElementById('boards-labels-toggle'),
    components: {
      GlToggle,
    },
    store,
    data: {
      toggleLabel: __('Show labels'),
    },
    computed: {
      ...mapState(['isShowingLabels']),
      ...mapGetters(['getSnowplowLabelToggleState']),
    },
    methods: {
      ...mapActions(['toggleShowLabels']),

      onToggle() {
        this.toggleShowLabels();

        Tracking.event(document.body.dataset.page, 'toggle', {
          label: 'show_labels',
          property: this.getSnowplowLabelToggleState,
        });
      },
    },
    template: `
      <div class="boards-labels-toggle-wrapper prepend-left-10">
        <span id="boards-labels-toggle-text">
          {{toggleLabel}}
        </span>
        <gl-toggle
          :value="isShowingLabels"
          class="prepend-left-10"
          label-on="Showing all labels"
          label-off="Hiding all labels"
          aria-describedby="boards-labels-toggle-text"
          data-qa-selector="show_labels_toggle"
          @change="onToggle"
        />
      </div>
    `,
  });
