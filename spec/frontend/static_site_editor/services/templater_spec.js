import templater from '~/static_site_editor/services/templater';

describe('templater', () => {
  const source = `Some text

<% some erb code %>

Some more text
`;
  const sourceTemplated = `Some text

\`\`\` sse
<% some erb code %>
\`\`\`

Some more text
`;

  it.each`
    isWrap   | initial            | target
    ${true}  | ${source}          | ${sourceTemplated}
    ${true}  | ${sourceTemplated} | ${sourceTemplated}
    ${false} | ${sourceTemplated} | ${source}
    ${false} | ${source}          | ${source}
  `(
    'wraps $initial in a templated sse codeblock when $isWrap and unwraps otherwise',
    ({ isWrap, initial, target }) => {
      expect(templater(isWrap, initial)).toMatch(target);
    },
  );
});
