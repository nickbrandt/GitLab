export const trace = state => state.logs.lines.join('\n');

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
