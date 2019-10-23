export const trace = state => {
  if (state.logs.lines) {
    return state.logs.lines.join('\n');
  }
  return '';
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
