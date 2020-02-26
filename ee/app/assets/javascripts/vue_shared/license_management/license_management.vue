<script>
import { mapState, mapActions } from 'vuex';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import AddLicenseForm from './components/add_license_form.vue';
import AdminLicenseManagementRow from './components/admin_license_management_row.vue';
import LicenseManagementRow from './components/license_management_row.vue';
import DeleteConfirmationModal from './components/delete_confirmation_modal.vue';
import PaginatedList from '~/vue_shared/components/paginated_list.vue';

import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_management/store/constants';

export default {
  name: 'LicenseManagement',
  components: {
    AddLicenseForm,
    DeleteConfirmationModal,
    AdminLicenseManagementRow,
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
    return {
      formIsOpen: false,
      tableHeaders: [
        { className: 'section-70', label: s__('Licenses|Policy') },
        { className: 'section-30', label: s__('Licenses|Name') },
      ],
    };
  },
  computed: {
    ...mapState(LICENSE_MANAGEMENT, ['managedLicenses', 'isLoadingManagedLicenses', 'isAdmin']),
  },
  mounted() {
    this.setAPISettings({
      apiUrlManageLicenses: this.apiUrl,
    });
    this.fetchManagedLicenses();
  },
  methods: {
    ...mapActions(LICENSE_MANAGEMENT, [
      'fetchManagedLicenses',
      'setAPISettings',
      'setLicenseApproval',
    ]),
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
    <delete-confirmation-modal v-if="isAdmin" />

    <paginated-list
      :list="managedLicenses"
      :empty-search-message="$options.emptySearchMessage"
      :empty-message="$options.emptyMessage"
      :filterable="isAdmin"
      filter="name"
      data-qa-selector="license_compliance_list"
    >
      <template #header>
        <gl-button
          v-if="isAdmin"
          class="js-open-form order-1"
          :disabled="formIsOpen"
          variant="success"
          data-qa-selector="license_add_button"
          @click="openAddLicenseForm"
        >
          {{ s__('LicenseCompliance|Add a license') }}
        </gl-button>

        <template v-else>
          <div
            v-for="header in tableHeaders"
            :key="header.label"
            class="table-section"
            :class="header.className"
            role="rowheader"
          >
            {{ header.label }}
          </div>
        </template>
      </template>

      <template v-if="isAdmin" #subheader>
        <div v-if="formIsOpen" class="prepend-top-default append-bottom-default">
          <add-license-form
            :managed-licenses="managedLicenses"
            @addLicense="setLicenseApproval"
            @closeForm="closeAddLicenseForm"
          />
        </div>
      </template>

      <template #default="{ listItem }">
        <admin-license-management-row v-if="isAdmin" :license="listItem" />
        <license-management-row v-else :license="listItem" />
      </template>
    </paginated-list>
  </div>
</template>
