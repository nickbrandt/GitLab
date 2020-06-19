import Vue from 'vue'
import IntegrationForm from '../components/integration_form.vue';
import { createStore } from '../stores'


export default () => {
    const entryPoint = document.querySelector('#js-cluster-integration-form')
<<<<<<< HEAD
=======
    const  data  = entryPoint.innerHTML;
    console.log(data)
    const jsonData = JSON.parse(data)
    //const jsonData = data.to_json 

    console.log(jsonData["enabled"])

>>>>>>> b224cc6b3333a8b554fc8c6025566be091ffe116

    if(!entryPoint) {
        return;
    }

<<<<<<< HEAD

    new Vue({
        el: '#js-cluster-integration-form',
        store: createStore(entryPoint.dataset),


        render(createElement) {
            return createElement(IntegrationForm)      
        }
    })
   
=======
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
>>>>>>> b224cc6b3333a8b554fc8c6025566be091ffe116
};


    
