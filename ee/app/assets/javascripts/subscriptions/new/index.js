import Vue from 'vue';
import store from './store';
import Checkout from './components/checkout.vue';

export default () => {
  const checkoutEl = document.getElementById('checkout');

  return new Vue({
    el: checkoutEl,
    store,
    components: {
      Checkout,
    },
    render(createElement) {
      return createElement('checkout', {});
    },
  });
};
