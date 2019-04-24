import terminal from './plugins/terminal';

const plugins = [terminal];

export default (store, el) => {
  // plugins is actually an array of plugin factories, so we have to create first then call
  plugins.forEach(plugin => plugin(el)(store));

  return store;
};
