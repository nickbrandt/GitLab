export default {
  data() {
    return {
      isDescriptionVersionExpanded: false,
    };
  },
  computed: {
    canSeeDescriptionVersion() {
      return Boolean(
        this.note.description_diff_path &&
          this.note.description_version_id &&
          !this.note.description_version_deleted,
      );
    },
    canDeleteDescriptionVersion() {
      return this.note.can_delete_description_version;
    },
    shouldShowDescriptionVersion() {
      return this.canSeeDescriptionVersion && this.isDescriptionVersionExpanded;
    },
    descriptionVersionToggleIcon() {
      return this.isDescriptionVersionExpanded ? 'chevron-up' : 'chevron-down';
    },
  },
  methods: {
    toggleDescriptionVersion() {
      this.isDescriptionVersionExpanded = !this.isDescriptionVersionExpanded;

      if (this.descriptionVersion) {
        return false;
      }

      const endpoint = this.note.description_diff_path;
      const startingVersion = this.note.start_description_version_id;

      return this.fetchDescriptionVersion({ endpoint, startingVersion });
    },
    deleteDescriptionVersion() {
      const endpoint = this.note.delete_description_version_path;
      const startingVersion = this.note.start_description_version_id;

      return this.softDeleteDescriptionVersion({ endpoint, startingVersion });
    },
  },
};
