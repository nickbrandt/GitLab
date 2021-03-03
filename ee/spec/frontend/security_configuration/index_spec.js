import Vue, { nextTick } from 'vue';
import { initSecurityConfiguration } from 'ee/security_configuration';
import { resetHTMLFixture } from 'helpers/fixtures';
import { someEnabledEl, noneEnabledEl, someEnabledWithAutoDevOpsEl } from './mock_data';

const errorsAndWarnings = [];

Vue.config.errorHandler = Vue.config.warnHandler = (error, vm, info) => {
  errorsAndWarnings.push(`Vue error/warning: Message: ${error}

vm.name: ${vm.name}
info: ${JSON.stringify(info)}
  `);
};

// Not using GlFeatureFlagsPlugin because it eagerly reads from gon, whereas
// this is lazy. This allows the gon.features to be changed before each test.
Vue.mixin({
  provide() {
    return {
      glFeatures: { ...((window.gon && window.gon.features) || {}) },
    };
  },
});

describe('Security Configuration App', () => {
  describe.each`
    context                                | mountElHtml
    ${'some enabled scanners (gitlab-ui)'} | ${someEnabledEl}
    ${'no enabled scanners'}               | ${noneEnabledEl}
    ${'some enabled by ADO'}               | ${someEnabledWithAutoDevOpsEl}
  `('given $context', ({ mountElHtml }) => {
    beforeEach(() => {
      setFixtures(mountElHtml);

      const el = document.querySelector('#js-security-configuration');
      gon.features = {
        // Mimic production; this will be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/235135
        sastConfigurationUi: true,

        // This is a temporary flag just for this spike. Used to switch between
        // re-architected implementation and original.
        newSecurityConfiguration: true,
      };
      initSecurityConfiguration(el);

      return nextTick();
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('matches the snapshot', () => {
      expect(errorsAndWarnings).toEqual([]);
      expect(document.body).toMatchSnapshot();
    });
  });
});
