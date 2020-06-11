import { parseToFileObjects } from '~/ide/stores/modules/file_system/utils/parse';

const TEST_DATA = [
  '123.txt',
  'LICENSE',
  'NEW_FILE',
  'NEW_FILE2',
  'README.md',
  'config/temp.config.js',
  'config/test.config.js',
  'lorem/C.md',
  'src/test/ANOTHER_NEW_FILE',
  'test',
];

describe('~/ide/stores/modules/file_system/utils/parse', () => {
  it('should parse', () => {
    expect(parseToFileObjects(TEST_DATA)).toMatchSnapshot();
  });
});
