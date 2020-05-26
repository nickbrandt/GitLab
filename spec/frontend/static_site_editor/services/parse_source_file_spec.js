import {
  sourceContent as content,
  sourceContentHeader as header,
  sourceContentBody as body,
} from '../mock_data';

import parseSourceFile from '~/static_site_editor/services/parse_source_file';

describe('parseSourceFile', () => {
  const contentSimple = content;
  const contentComplex = [content, content, content].join('');

  it.each`
    sourceContent     | raw               | sourceHeader | sourceBody | desc
    ${contentSimple}  | ${contentSimple}  | ${header}    | ${body}    | ${'extracts header'}
    ${contentComplex} | ${contentComplex} | ${header}    | ${null}    | ${'extracts body'}
  `('$desc', ({ sourceContent, raw, sourceHeader, sourceBody }) => {
    const result = parseSourceFile(sourceContent);
    // The complex body isn't known until parsed so we simply subtract the `header` from `raw` to get it
    const parsedBody = sourceBody === null ? result.raw.replace(result.header, '') : sourceBody;

    expect(result).toMatchObject({ raw, header: sourceHeader, body: parsedBody });
  });

  it('returns the same front matter regardless of front matter duplication', () => {
    const parsedSourceSimple = parseSourceFile(contentSimple);
    const parsedSourceComplex = parseSourceFile(contentComplex);

    expect(parsedSourceSimple.header).toBe(parsedSourceComplex.header);
  });
});
