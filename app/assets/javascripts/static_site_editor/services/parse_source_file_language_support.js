import { yaml, json } from './parse_source_file_engine_defaults';

const frontMatterLanguageDefinitions = [
  { name: 'yaml', open: '---', close: '---', engine: yaml },
  { name: 'toml', open: '+++', close: '+++', engine: null },
  { name: 'json', open: '{', close: '}', engine: json },
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
