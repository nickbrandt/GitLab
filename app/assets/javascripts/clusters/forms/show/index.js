import Vue from 'vue'
import IntegrationForm from '../components/integration_form.vue';


export default () => {
    const entryPoint = document.querySelector('#js-cluster-integration-form')
    const dataset = entryPoint.dataset;

    if(!entryPoint) {
        return;
    }

    new Vue({
        el: '#js-cluster-integration-form',
        render(createElement) {
          return createElement(IntegrationForm);
        },
      });
    };


    
