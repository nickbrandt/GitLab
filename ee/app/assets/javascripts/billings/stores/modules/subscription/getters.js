export const isFreePlan = state => state.plan.code === null;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
