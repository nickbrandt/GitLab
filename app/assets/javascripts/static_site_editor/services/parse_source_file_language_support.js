import { __ } from '~/locale';
import { yaml, json } from './parse_source_file_engines';

const resolver = engine => resolve => resolve(engine);
const rejector = reject => reject(new Error(__('Front matter engine load failure.')));
const loader = engine => () => new Promise(resolver(engine), rejector);

const frontMatterLanguageDefinitions = [
  { name: 'yaml', open: '---', close: '---', loadEngine: loader(yaml) },
  { name: 'toml', open: '+++', close: '+++', loadEngine: loader(null) },
  { name: 'json', open: '{', close: '}', loadEngine: loader(json) },
];

const reInferredOpenDelimiter = /^(.+)\n/;

const inferDelimiter = source => {
  const matches = source.match(reInferredOpenDelimiter);
  const capturedDelimiter = matches.length ? matches[1] : null;
  return capturedDelimiter;
};

const getFrontMatterLanguageDefinition = source => {
  const delimiter = inferDelimiter(source);
  const languageDefinition = frontMatterLanguageDefinitions.find(def => def.open === delimiter);

  if (!languageDefinition) {
    throw new Error(`Unsupported front matter language with delimiter: ${delimiter}`);
  }

  return languageDefinition;
};

export default getFrontMatterLanguageDefinition;
