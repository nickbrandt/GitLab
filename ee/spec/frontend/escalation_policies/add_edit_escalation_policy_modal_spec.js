import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AddEscalationPolicyForm from 'ee/escalation_policies/components/add_edit_escalation_policy_form.vue';
import AddEscalationPolicyModal, {
  i18n,
} from 'ee/escalation_policies/components/add_edit_escalation_policy_modal.vue';

describe('AddEscalationPolicyModal', () => {
  let wrapper;
  const projectPath = 'group/project';

  const createComponent = ({ escalationPolicy, data } = {}) => {
    wrapper = shallowMount(AddEscalationPolicyModal, {
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        escalationPolicy,
      },
      provide: {
        projectPath,
      },
    });
  };
  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findEscalationPolicyForm = () => wrapper.findComponent(AddEscalationPolicyForm);

  describe('renders create modal with the correct information', () => {
    it('renders modal title', () => {
      expect(findModal().attributes('title')).toBe(i18n.addEscalationPolicy);
    });

    it('renders the form inside the modal', () => {
      expect(findEscalationPolicyForm().exists()).toBe(true);
    });
  });

  describe('modal buttons', () => {
    it('should disable primary button when form is invalid', async () => {
      findEscalationPolicyForm().vm.$emit('update-escalation-policy-form', {
        field: 'name',
        value: '',
      });
      await wrapper.vm.$nextTick();
      expect(findModal().props('actionPrimary').attributes).toContainEqual({ disabled: true });
    });

    it('should enable primary button when form is valid', async () => {
      findEscalationPolicyForm().vm.$emit('update-escalation-policy-form', {
        field: 'name',
        value: 'Some policy name',
      });
      await wrapper.vm.$nextTick();
      expect(findModal().props('actionPrimary').attributes).toContainEqual({ disabled: false });
    });
  });
});
