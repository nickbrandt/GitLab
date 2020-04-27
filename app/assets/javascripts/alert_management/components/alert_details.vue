<script>
import { GlNewDropdown, GlNewDropdownItem, GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';

/* eslint-disable import/no-commonjs */
const mock = require('./alerts.json');

export default {
  statuses: {
    triggered: s__('AlertManagement|Triggered'),
    acknowledged: s__('AlertManagement|Acknowledged'),
    ignored: s__('AlertManagement|Ignored'),
  },
  i18n: {
    fullAlertDetailsTitle: s__('AlertManagement|Full Alert Details'),
    overviewTitle: s__('AlertManagement|Overview'),
  },
  components: {
    GlNewDropdown,
    GlNewDropdownItem,
    GlTab,
    GlTabs,
  },
};
</script>
<template>
  <div>
    <div class="d-flex justify-content-between">
      <gl-tabs>
        <gl-tab data-testid="overviewTab" :title="$options.i18n.overviewTitle">
          <ul class="pl-3">
            <li data-testid="startTimeItem" class="font-weight-bold mb-3 mt-2">
              {{ s__('AlertManagement|Start time:') }}
            </li>
            <li class="font-weight-bold my-3">
              {{ s__('AlertManagement|End time:') }}
            </li>
            <li class="font-weight-bold my-3">
              {{ s__('AlertManagement|Events:') }}
            </li>
          </ul>
        </gl-tab>
        <gl-tab data-testid="fullDetailsTab" :title="$options.i18n.fullAlertDetailsTitle" />
      </gl-tabs>
    </div>
    <div class="d-flex justify-content-between">
      <gl-new-dropdown :text="alertDetails[0].status">
        <gl-new-dropdown-item
          v-for="(label, field) in $options.statuses"
          :key="field"
          class="align-middle"
          >{{ label }}
        </gl-new-dropdown-item>
      </gl-new-dropdown>
    </div>
  </div>
</template>
