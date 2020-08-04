// eslint-disable-next-line @gitlab/require-i18n-strings
const marker = ' sse';
const ticks = '```';
const prefix = `${ticks}${marker}\n`;
const postfix = `\n${ticks}`;
const code = '.| |\\t|\\n(?!\\n)';
const templatedRegex = new RegExp(`(^${prefix}(${code})+${postfix}$)`, 'gm');
const embeddedRubyRegex = new RegExp(`(^<%(${code})+%>$)`, 'gm');

const unwrap = source => {
  let text = source;
  const matches = text.match(templatedRegex);
  if (matches) {
    matches.forEach(match => {
      const initial = match.replace(prefix, '').replace(postfix, '');
      text = text.replace(match, initial);
    });
  }
  return text;
};

const wrap = source => {
  let text = unwrap(source);
  const matches = text.match(embeddedRubyRegex);
  if (matches) {
    matches.forEach(match => {
      text = text.replace(match, `${prefix}${match}${postfix}`);
    });
  }
  return text;
};

const template = (isWrap, source) => (isWrap ? wrap(source) : unwrap(source));

export default template;
