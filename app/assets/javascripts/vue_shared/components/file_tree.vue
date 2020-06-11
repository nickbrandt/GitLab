<script>
export default {
  name: 'FileTree',
  props: {
    fileRowComponent: {
      type: Object,
      required: true,
    },
    level: {
      type: Number,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
    files: {
      type: Object,
      required: true,
    },
  },
  computed: {
    childFilesLevel() {
      return this.file.isHeader ? 0 : this.level + 1;
    },
    file() {
      return this.files[this.filePath];
    },
  },
};
</script>

<template>
  <div>
    <component
      :is="fileRowComponent"
      :level="level"
      :file="file"
      v-bind="$attrs"
      v-on="$listeners"
    />
    <template v-if="file.opened || file.isHeader">
      <file-tree
        v-for="{ name } in file.children"
        :key="name"
        :file-row-component="fileRowComponent"
        :level="childFilesLevel"
        :files="files"
        :file-path="`${filePath}/${name}`"
        v-bind="$attrs"
        v-on="$listeners"
      />
    </template>
  </div>
</template>
