import { shallowMount } from '@vue/test-utils';

import ServiceCredentialsForm from '~/create_cluster/eks_cluster/components/service_credentials_form.vue';

describe('ServiceCredentialsForm', () => {
  let vm;
  const accountId = 'accountId';
  const externalId = 'externalId';

  beforeEach(() => {
    vm = shallowMount(ServiceCredentialsForm, {
      propsData: {
        accountId,
        externalId,
        accountAndExternalIdsHelpPath: '',
        createRoleArnHelpPath: '',
      },
    });
  });
  afterEach(() => vm.destroy());

  const findAccountIdInput = () => vm.find('#gitlab-account-id');
  const findCopyAccountIdButton = () => vm.find('.js-copy-account-id-button');
  const findExternalIdInput = () => vm.find('#eks-external-id');
  const findCopyExternalIdButton = () => vm.find('.js-copy-external-id-button');
  const findSubmitButton = () => vm.find('.js-submit-service-credentials');

  it('displays provided account id', () => {
    expect(findAccountIdInput().attributes('value')).toBe(accountId);
  });

  it('allows to copy account id', () => {
    expect(findCopyAccountIdButton().props('text')).toBe(accountId);
  });

  it('displays provided external id', () => {
    expect(findExternalIdInput().attributes('value')).toBe(externalId);
  });

  it('allows to copy external id', () => {
    expect(findCopyExternalIdButton().props('text')).toBe(externalId);
  });

  it('disables submit button when role ARN is not provided', () => {
    expect(findSubmitButton().attributes('disabled')).toBeTruthy();
  });

  it('enables submit button when role ARN is not provided', () => {
    vm.setData({ roleArn: '123' });

    expect(findSubmitButton().attributes('disabled')).toBeFalsy();
  });
});
