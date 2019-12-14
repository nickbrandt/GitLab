<script>
import { mapState, mapActions } from 'vuex';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import AddLicenseForm from './components/add_license_form.vue';
import LicenseManagementRow from './components/license_management_row.vue';
import DeleteConfirmationModal from './components/delete_confirmation_modal.vue';
import PaginatedList from '~/vue_shared/components/paginated_list.vue';
import createStore from './store/index';

const store = createStore();

export default {
  name: 'LicenseManagement',
  components: {
    AddLicenseForm,
    DeleteConfirmationModal,
    LicenseManagementRow,
    GlButton,
    GlLoadingIcon,
    PaginatedList,
  },
  props: {
    apiUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return { formIsOpen: false };
  },
  store,
  computed: {
    ...mapState(['managedLicenses', 'isLoadingManagedLicenses']),
  },
  mounted() {
    this.setAPISettings({
      apiUrlManageLicenses: this.apiUrl,
    });
    this.loadManagedLicenses();
  },
  methods: {
    ...mapActions(['loadManagedLicenses', 'setAPISettings', 'setLicenseApproval']),
    openAddLicenseForm() {
      this.formIsOpen = true;
    },
    closeAddLicenseForm() {
      this.formIsOpen = false;
    },
  },
  emptyMessage: s__(
    'LicenseCompliance|There are currently no approved or blacklisted licenses in this project.',
  ),
  emptySearchMessage: s__(
    'LicenseCompliance|There are currently no approved or blacklisted licenses that match in this project.',
  ),
};
</script>
<template>
  <gl-loading-icon v-if="isLoadingManagedLicenses" />
  <div v-else class="license-management">
    <delete-confirmation-modal />

    <paginated-list
      :list="managedLicenses"
      :empty-search-message="$options.emptySearchMessage"
      :empty-message="$options.emptyMessage"
      filter="name"
      data-qa-selector="license_compliance_list"
    >
      <template #header>
        <gl-button
          class="js-open-form order-1"
          :disabled="formIsOpen"
          variant="success"
          data-qa-selector="license_add_button"
          @click="openAddLicenseForm"
        >
          {{ s__('LicenseCompliance|Add a license') }}
        </gl-button>
      </template>

      <template #subheader>
        <div v-if="formIsOpen" class="prepend-top-default append-bottom-default">
          <add-license-form
            :managed-licenses="managedLicenses"
            @addLicense="setLicenseApproval"
            @closeForm="closeAddLicenseForm"
          />
        </div>
      </template>

      <template #default="{ listItem }">
        <license-management-row :license="listItem" />
      </template>
    </paginated-list>
  </div>
</template>
