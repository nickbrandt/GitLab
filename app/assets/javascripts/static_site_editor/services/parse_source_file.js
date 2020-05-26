const parseSourceFile = raw => {
  const frontMatterRegex = /(^---$[\s\S]*?^---$)/m;
  const hasFrontMatter = frontMatterRegex.test(raw);
  let header = null;
  let body = raw;

  if (hasFrontMatter) {
    /*
    Due to capturing group of regexp `.split()` includes at minimum three items (preFrontMatter, frontMatter, content)
    - preFrontMatter: Intentionally discarded, only account for this situation if it happens in practice (if a non-empty string above frontMatter exists)
    - frontMatter: First match using frontMatterRegex (non-greedy via `?` such that code blocks with frontMatter syntax don't match for example)
    - content: All remaining text (as previously mentioned, code blocks with frontMatter may occur resulting in more than one item)
    */
    const [, frontMatter, ...content] = raw.split(frontMatterRegex);
    header = frontMatter;
    body = content.join('');
  }

  return { raw, header, body };
};

export default parseSourceFile;
