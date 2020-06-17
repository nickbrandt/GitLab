import Vue from 'vue'
import IntegrationForm from '../components/integration_form.vue';
import { createStore } from '../stores'


export default () => {
    const entryPoint = document.querySelector('#js-cluster-integration-form')
    const  data  = entryPoint.innerHTML;
    console.log(data)
    const jsonData = JSON.parse(data)
    //const jsonData = data.to_json 

    console.log(jsonData["enabled"])


    if(!entryPoint) {
        return;
    }

    new Vue({
        el: '#js-cluster-integration-form',
        store: createStore({
            initialState: {
                clusterEnabled: jsonData["enabled"],
                clusterDomain:jsonData["domain"],
                clusterEnvironmentScope: jsonData["environment_scope"],
            },
        }),


        render(createElement) {
            return createElement(IntegrationForm, {
                props: {
                    clusterEnabled, 
                    clusterDomain, 
                    clusterEnvironmentScope, 
                }
            });
        },
    });
};


    
