<script>
import linkifyHtml from 'linkifyjs/html';
import LineNumber from './line_number.vue';

const linkifyOptions = {
  className: '',
  defaultProtocol: 'https',
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
          innerHTML: linkifyHtml(content.text, linkifyOptions),
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
