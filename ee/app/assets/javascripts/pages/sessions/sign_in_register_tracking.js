import Tracking from '~/tracking';

export default () => {
  const container = document.getElementById('#signin-container');
  new Tracking().bind(container);
};
