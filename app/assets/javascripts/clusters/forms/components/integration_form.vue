<script>
import { GlForm, GlToggle, GlFormGroup,  GlTooltip, GlTooltipDirective, GlButton, GlLink } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';

import { mapState, mapActions } from 'vuex';

export default {
    components: {
        GlFormGroup,
        GlForm,
        GlToggle,
        GlTooltip,
        GlLink,
        GlButton,
    },

    directives: {
        GlTooltip: GlTooltipDirective,
    },

    computed: {
        ...mapState(['clusterEnabled', 'clusterDomain', 'clusterEnvironmentScope']),
       
    },

    props: {
       
        clusterEnabled: {
            type: Boolean, 
            required: true,
        }, 
         clusterDomain: {
            type: String, 
            required: true,
        }, 
         clusterEnvironmentScope: {
            type: String, 
            required: true,
        }, 
                
    },


    props: {
        //change this to @cluster.enabled?
        initialIntegrationEnabled: {
            type: Boolean,
            value: true
        },
        
    },
    data() {
        return {
            integrationEnabled: this.initialIntegrationEnabled,
        };
    },
    mounted() {
    // Initialize view
    this.$nextTick(() => {
      this.onToggle(this.integrationEnabled);
    });
  },

   methods: {
    onToggle(e) {
        console.log("TOGGLED")
        console.log(e)
        console.log(this.tester)
       // console.log(this.items)
        
    },
  },

   
}
</script>

<template>
    <div class="d-flex align-items-center">
        <gl-form>
            <gl-form-group>
                <div display="inline-block">            
                    <h4 pr-2 m-0> {{ s__('ClusterIntegration|GitLab Integration') }} </h4>
                    <div id="tooltipcontainer">
                        <gl-toggle 
                            v-model="integrationEnabled" 
                            v-gl-tooltip:tooltipcontainer 
                            :title="s__('ClusterIntegration|Enable or disable GitLab\'s connection to your Kubernetes cluster.')"
                            @change="onToggle"
                        />
                    </div>
                </div>
            </gl-form-group>
        </gl-form>
    </div>
</template>