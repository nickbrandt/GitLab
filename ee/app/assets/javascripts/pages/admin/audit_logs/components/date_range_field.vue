<script>
import { GlDaterangePicker } from '@gitlab/ui';

import { parsePikadayDate, pikadayToString } from '~/lib/utils/datetime_utility';
import { queryToObject } from '~/lib/utils/url_utility';

export default {
  name: 'DateRangeField',
  components: {
    GlDaterangePicker,
  },
  props: {
    formElement: {
      type: HTMLFormElement,
      required: true,
    },
  },
  data() {
    const data = {
      startDate: null,
      endDate: null,
    };

    const { created_after: initialStartDate, created_before: initialEndDate } = queryToObject(
      window.location.search,
    );

    if (initialStartDate) {
      data.startDate = parsePikadayDate(initialStartDate);
    }

    if (initialEndDate) {
      data.endDate = parsePikadayDate(initialEndDate);
    }

    return data;
  },
  computed: {
    createdAfter() {
      return this.startDate ? pikadayToString(this.startDate) : '';
    },
    createdBefore() {
      return this.endDate ? pikadayToString(this.endDate) : '';
    },
  },
  methods: {
    handleInput(dates) {
      this.startDate = dates.startDate;
      this.endDate = dates.endDate;

      this.$nextTick(() => this.formElement.submit());
    },
  },
};
</script>

<template>
  <div>
    <gl-daterange-picker
      class="d-flex flex-wrap flex-sm-nowrap"
      :default-start-date="startDate"
      :default-end-date="endDate"
      start-picker-class="form-group align-items-lg-center mr-0 mr-sm-1 d-flex flex-column flex-lg-row"
      end-picker-class="form-group align-items-lg-center mr-0 mr-sm-2 d-flex flex-column flex-lg-row"
      @input="handleInput"
    />
    <input type="hidden" name="created_after" :value="createdAfter" />
    <input type="hidden" name="created_before" :value="createdBefore" />
  </div>
</template>
