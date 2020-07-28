import {
  SNIPPET_MARK_VIEW_APP_START,
  SNIPPET_MARK_BLOB_CONTENT,
  SNIPPET_MEASURE_BLOB_CONTENT,
  SNIPPET_MEASURE_BLOB_CONTENT_WITHIN_APP,
} from '~/performance_constants';

export default {
  props: {
    content: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  mounted() {
    window.requestAnimationFrame(() => {
      performance.mark(SNIPPET_MARK_BLOB_CONTENT);
      performance.measure(SNIPPET_MEASURE_BLOB_CONTENT);
      performance.measure(SNIPPET_MEASURE_BLOB_CONTENT_WITHIN_APP, SNIPPET_MARK_VIEW_APP_START);
    });
  }
};
