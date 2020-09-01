// Inspired gray-matter use from https://github.com/jonschlinkert/gray-matter/blob/master/lib/engines.js

import jsYaml from 'js-yaml';

export const yaml = {
  parse: jsYaml.safeLoad.bind(jsYaml),
  stringify: jsYaml.safeDump.bind(jsYaml),
};

export const json = {
  parse: JSON.parse.bind(JSON),
  stringify: (obj, options) => {
    const opts = { replacer: null, space: 2, ...options };
    return JSON.stringify(obj, opts.replacer, opts.space);
  },
};
