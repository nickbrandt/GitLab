<script>
import { GlForm, GlToggle, GlFormGroup,  GlTooltip, GlTooltipDirective, GlButton, GlLink } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';

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

    data() {
        return {
            //change this to @cluster.enabled?
        integrationEnabled: true,
        
        };
    }
}
</script>

<template>
    <div class="d-flex align-items-center">
        <gl-form>
            <gl-form-group>
                <div display="inline-block">            
                    <h4 pr-2 m-0> {{ s__('ClusterIntegration|GitLab Integration') }} </h4>
                    <div id="tooltipcontainer">
                        <gl-toggle v-model="integrationEnabled" v-gl-tooltip:tooltipcontainer :title="s__('ClusterIntegration|Enable or disable GitLab\'s connection to your Kubernetes cluster.')"/>
                    </div>
                </div>
            </gl-form-group>
        </gl-form>
    </div>
</template>