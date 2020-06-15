import Vue from 'vue'
import IntegrationForm from '../components/integration_form.vue';


export default () => {
    console.log("my form function")

    const entryPoint = document.querySelector('#js-cluster-integration-form')
    console.log(entryPoint)
    if(!entryPoint) {
        return;
    }
    new Vue({
        el: '#js-cluster-integration-form',
       // store: createStore(entryPoint.dataset),
        render(createElement) {
          return createElement(IntegrationForm);
        },
      });
    };


    
