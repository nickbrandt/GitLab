import Vue from 'vue'
import IntegrationForm from '../components/integration_form.vue';
import { createStore } from '../stores'


export default () => {
    const entryPoint = document.querySelector('#js-cluster-integration-form')
    const { endpoint } = entryPoint.dataset;

    if(!entryPoint) {
        return;
    }

    new Vue({
        el: '#js-cluster-integration-form',
        store: createStore({ endpoint }),
        render(createElement) {
            return createElement(IntegrationForm);
        },
      });
    };


    
