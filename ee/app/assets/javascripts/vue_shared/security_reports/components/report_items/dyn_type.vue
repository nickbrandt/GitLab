<script>
function camelToKebab(data) {
  return data.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
}

export default {
  name: 'ReportDynType',
  components: {},
  props: {
    item: {
      type: Object,
      required: true,
    },
    vuln: {
      type: Object,
      required: true,
    },
  },
  beforeCreate() {
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemMarkdown = require('./types/markdown.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemDiff = require('./types/diff.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemFileLocation = require('./types/file_location.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemModuleLocation = require('./types/module_location.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemNamedList = require('./types/named_list.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemText = require('./types/text.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemInt = require('./types/int.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemCode = require('./types/code.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemUrl = require('./types/url.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemCommit = require('./types/commit.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemList = require('./types/list.vue').default;
    // eslint-disable-next-line global-require
    this.$options.components.ReportItemTable = require('./types/table.vue').default;
  },
  methods: {
    isValidComponentType(type) {
      const validTypes = Object.keys(this.$options.components).map((name) => camelToKebab(name));
      return validTypes.indexOf(type) !== -1;
    },
  },
};
</script>

<template>
  <component
    :is="'report-item-' + item.type"
    v-if="isValidComponentType('report-item-' + item.type)"
    v-bind="item"
    :vuln="vuln"
  />
</template>
