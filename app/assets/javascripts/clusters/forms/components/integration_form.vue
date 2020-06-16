<script>
import { GlForm, GlToggle, GlFormGroup,  GlTooltip, GlTooltipDirective, GlButton } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
export default {
    components: {
        GlFormGroup,
        GlForm,
        GlToggle,
        GlTooltip,
        GlTooltipDirective,
        GlButton,
    },
    directives: {
        GlTooltip: GlTooltipDirective,
    }
}
</script>

<template>
    <div class="d-flex align-items-center">
        <gl-form-group>
            <gl-form>
                <h4 pr-2 m-0> {{ s__('ClusterIntegration|GitLab Integration') }} </h4>


                <div id="tooltipcontainer">
                    <gl-toggle v-gl-tooltip:tooltipcontainer :title="s__('ClusterIntegration|Enable or disable GitLab\'s connection to your Kubernetes cluster.')">

                    </gl-toggle>
                </div>

                
            </gl-form>
        </gl-form-group>
    </div>
</template>