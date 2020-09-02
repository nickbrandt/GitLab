<script>
import Jed from 'jed';
import { languageCode } from "~/locale";

export default {
  name: 'ReportItemLabel',
  components: {
  },
  props: {
    name: {
      type: Array,
      required: true,
    },
    description: {
      type: Array,
      required: true,
    }
  },
  computed: {
    langText() {
    }
  },
  mounted() {
    let langItems = {
      name: [],
      description: [],
    };
    this.name.forEach(item => langItems
    this.locale = new Jed();
  }
}
</script>

<template>
  <tr>
    <td class="report-item-label-td">
        <label class="font-weight-bold">{{langText}}</label>
    </td>
  </tr>
</template>
