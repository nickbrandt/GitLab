import jsYaml from 'js-yaml';

const NEW_LINE = '\n';

export const frontMatterify = source => {
  let index = 3;
  let offset;
  const delimiter = source.slice(0, index);
  const type = 'yaml';
  const NO_FRONTMATTER = {
    source,
    matter: null,
    spacing: null,
    content: source,
    delimiter: null,
    type: null,
  };

  if (!type || source.charAt(index) !== NEW_LINE) {
    return NO_FRONTMATTER;
  }

  offset = source.indexOf(delimiter, index);

  // Finds the end delimiter that starts at a new line
  while (offset !== -1 && source.charAt(offset - 1) !== NEW_LINE) {
    index = offset + delimiter.length;
    offset = source.indexOf(delimiter, index);
  }

  if (offset === -1) {
    return NO_FRONTMATTER;
  }

  const matterStr = source.slice(index, offset);
  const matter = jsYaml.safeLoad(matterStr);

  let content = source.slice(offset + delimiter.length);
  let spacing = '';
  let idx = 0;
  while (content.charAt(idx).match(/(\s|\n)/)) {
    spacing += content.charAt(idx);
    idx += 1;
  }
  content = content.replace(spacing, '');

  return {
    source,
    matter,
    spacing,
    content,
    delimiter,
    type,
  };
};

export const stringify = ({ matter, spacing, content, delimiter }, newMatter) => {
  const matterObj = newMatter || matter;

  if (!matterObj) {
    return content;
  }

  const header = `${delimiter}${NEW_LINE}${jsYaml.safeDump(matterObj)}${delimiter}`;
  const body = `${spacing}${content}`;
  return `${header}${body}`;
};
