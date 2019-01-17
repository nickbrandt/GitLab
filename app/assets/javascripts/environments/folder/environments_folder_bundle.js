import Vue from 'vue';
import environmentsFolderApp from './environments_folder_view.vue';
import { parseBoolean } from '../../lib/utils/common_utils';
import Translate from '../../vue_shared/translate';

// ee-only start
import CanaryCalloutMixin from 'ee/environments/mixins/canary_callout_mixin'; // eslint-disable-line import/order
// ee-only end

Vue.use(Translate);

export default () =>
  new Vue({
    el: '#environments-folder-list-view',
    components: {
      environmentsFolderApp,
    },
    // ee-only start
    mixins: [CanaryCalloutMixin],
    // ee-only end
    data() {
      const environmentsData = document.querySelector(this.$options.el).dataset;

      return {
        endpoint: environmentsData.environmentsDataEndpoint,
        folderName: environmentsData.environmentsDataFolderName,
        cssContainerClass: environmentsData.cssClass,
        canCreateDeployment: parseBoolean(environmentsData.environmentsDataCanCreateDeployment),
        canReadEnvironment: parseBoolean(environmentsData.environmentsDataCanReadEnvironment),
      };
    },
    render(createElement) {
      return createElement('environments-folder-app', {
        props: {
          endpoint: this.endpoint,
          folderName: this.folderName,
          cssContainerClass: this.cssContainerClass,
          canCreateDeployment: this.canCreateDeployment,
          canReadEnvironment: this.canReadEnvironment,
          // ee-only start
          canaryDeploymentFeatureId: this.canaryDeploymentFeatureId,
          showCanaryDeploymentCallout: this.showCanaryDeploymentCallout,
          userCalloutsPath: this.userCalloutsPath,
          lockPromotionSvgPath: this.lockPromotionSvgPath,
          helpCanaryDeploymentsPath: this.helpCanaryDeploymentsPath,
          // ee-only end
        },
      });
    },
  });
