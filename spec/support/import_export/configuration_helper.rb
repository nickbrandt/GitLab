# frozen_string_literal: true

module ConfigurationHelper
  ALLOWED_REFERENCES = Gitlab::ImportExport::RelationFactory::PROJECT_REFERENCES + Gitlab::ImportExport::RelationFactory::USER_REFERENCES + %w[group_id commit_id]
  PROHIBITED_REFERENCES = Regexp.union(/\Acached_markdown_version\Z/, /_id\Z/, /_html\Z/).freeze

  # Returns a list of models from hashes/arrays contained in +project_tree+
  def names_from_tree(project_tree)
    project_tree.map do |branch_or_model|
      branch_or_model =  branch_or_model.to_s if branch_or_model.is_a?(Symbol)

      branch_or_model.is_a?(String) ? branch_or_model : names_from_tree(branch_or_model)
    end
  end

  def config_hash
    Gitlab::ImportExport::Config.new.to_h.deep_stringify_keys
  end

  def relation_names
    names = names_from_tree(config_hash.dig('tree', 'project'))
    # Remove duplicated or add missing models
    # - project is not part of the tree, so it has to be added manually.
    # - milestone, labels, merge_request have both singular and plural versions in the tree, so remove the duplicates.
    # - User, Author... Models we do not care about for checking models
    names.flatten.uniq - %w(milestones labels user author merge_request) + ['project']
  end

  def relation_class_for_name(relation_name)
    relation_name = Gitlab::ImportExport::RelationFactory.overrides[relation_name.to_sym] || relation_name
    Gitlab::ImportExport::RelationFactory.relation_class(relation_name)
  end

  def parsed_attributes(relation_name, attributes)
    excluded_attributes = config_hash['excluded_attributes'][relation_name]
    included_attributes = config_hash['included_attributes'][relation_name]
    attributes = attributes - JSON[excluded_attributes.to_json] if excluded_attributes
    attributes = attributes & JSON[included_attributes.to_json] if included_attributes
    attributes
  end

  def prohibited_key?(key)
    key =~ PROHIBITED_REFERENCES && !permitted_key?(key)
  end

  def permitted_key?(key)
    ALLOWED_REFERENCES.include?(key)
  end

  def associations_for(safe_model)
    safe_model.reflect_on_all_associations.map { |assoc| assoc.name.to_s }
  end
end
