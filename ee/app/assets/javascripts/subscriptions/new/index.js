import Vue from 'vue';
import createStore from './store';
import Checkout from './components/checkout.vue';

export default () => {
  const checkoutEl = document.getElementById('checkout');

  return new Vue({
    el: checkoutEl,
    store: createStore(checkoutEl.dataset),
    render(createElement) {
      return createElement(Checkout);
    },
  });
};
