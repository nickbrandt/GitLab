<script>
import linkifyHtml from 'linkifyjs/html';
import LineNumber from './line_number.vue';
import { sanitize } from '~/lib/dompurify';

const linkifyOptions = {
  className: '',
  defaultProtocol: 'https',
  validate: {
    url: function(value) {
      return /^(http|ftp)s?:\/\//.test(value);
    },
  },
};

export default {
  functional: true,
  props: {
    line: {
      type: Object,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },
  render(h, { props }) {
    const { line, path } = props;

    const chars = line.content.map(content => {
      return h('span', {
        class: ['gl-white-space-pre-wrap', content.style],
        domProps: {
          innerHTML: sanitize(linkifyHtml(content.text, linkifyOptions), { ALLOWED_TAGS: ['a'] }),
        },
      });
    });

    return h('div', { class: 'js-line log-line' }, [
      h(LineNumber, {
        props: {
          lineNumber: line.lineNumber,
          path,
        },
      }),
      ...chars,
    ]);
  },
};
</script>
