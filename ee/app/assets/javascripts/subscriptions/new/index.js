import Vue from 'vue';
import Checkout from './components/checkout.vue';

export default () => {
  const checkoutEl = document.getElementById('checkout');

  return new Vue({
    el: checkoutEl,
    components: { Checkout },
    render(createElement) {
      return createElement('checkout', {});
    },
  });
};
