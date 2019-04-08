import SCIMTokenToggleArea from 'ee/saml_providers/scim_token_toggle_area';
import { TEST_HOST } from 'spec/test_constants';

const mockData = {
  data: {
    scim_token: 'foobar',
    scim_api_url: `${TEST_HOST}/scim/api`,
  },
};

describe('SCIMTokenToggleArea', () => {
  const FIXTURE = 'groups/saml_providers/show.html';
  let scimTokenToggleArea;
  let generateNewSCIMToken;
  preloadFixtures(FIXTURE);

  beforeEach(() => {
    loadFixtures(FIXTURE);

    generateNewSCIMToken = jasmine
      .createSpy('generateNewSCIMToken')
      .and.callFake(() => Promise.resolve(mockData));
    spyOnDependency(SCIMTokenToggleArea, 'SCIMTokenService').and.returnValue({
      generateNewSCIMToken,
    });

    scimTokenToggleArea = new SCIMTokenToggleArea(
      '.js-generate-scim-token-container',
      '.js-scim-token-container',
    );
  });

  describe('constructor', () => {
    it('receives a form which displays an obfuscated token', () => {
      expect(scimTokenToggleArea.scimTokenInput.value).toBe('********************');
    });

    it('displays the generate token form and hides the scim token form', () => {
      expect(scimTokenToggleArea.generateContainer).not.toHaveClass('d-none');
      expect(scimTokenToggleArea.formContainer).toHaveClass('d-none');
    });
  });

  describe('generateSCIMToken', () => {
    it('toggles the generate and scim token forms', done => {
      scimTokenToggleArea
        .generateSCIMToken()
        .then(() => {
          expect(scimTokenToggleArea.generateContainer).toHaveClass('d-none');
          expect(scimTokenToggleArea.formContainer).not.toHaveClass('d-none');
        })
        .then(done)
        .catch(done.fail);
    });

    it('populates the scim form with the token data', done => {
      scimTokenToggleArea
        .generateSCIMToken()
        .then(() => {
          expect(scimTokenToggleArea.scimTokenInput.value).toBe(mockData.data.scim_token);
          expect(scimTokenToggleArea.scimEndpointUrl.value).toBe(mockData.data.scim_api_url);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('resetSCIMToken', () => {
    it('does not trigger token generation when the confirm is canceled', () => {
      spyOn(window, 'confirm').and.returnValue(false);

      scimTokenToggleArea.resetSCIMToken();

      expect(generateNewSCIMToken).not.toHaveBeenCalled();
    });

    it('populates the scim form with the token data if the confirm is accepted', done => {
      spyOn(window, 'confirm').and.returnValue(true);

      scimTokenToggleArea
        .resetSCIMToken()
        .then(() => {
          expect(scimTokenToggleArea.scimTokenInput.value).toBe(mockData.data.scim_token);
          expect(scimTokenToggleArea.scimEndpointUrl.value).toBe(mockData.data.scim_api_url);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
