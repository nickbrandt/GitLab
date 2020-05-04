import $ from 'jquery';
import '~/behaviors/markdown/render_gfm';

export default {
  mounted() {
    this.renderGFM();
  },
  methods: {
    renderGFM() {
      $(this.$el).renderGFM();
    },
  },
};
