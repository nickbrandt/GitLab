# frozen_string_literal: true

module FeatureFlagHelpers
  def create_flag(project, name, active, description: nil)
    create(:operations_feature_flag, name: name, active: active,
                                     description: description, project: project)
  end

  def create_scope(feature_flag, environment_scope, active)
    create(:operations_feature_flag_scope,
      feature_flag: feature_flag,
      environment_scope: environment_scope,
      active: active)
  end

  def within_feature_flag_row(index)
    within ".gl-responsive-table-row:nth-child(#{index + 1})" do
      yield
    end
  end

  def within_feature_flag_scopes
    within '.js-feature-flag-environments' do
      yield
    end
  end

  def within_scope_row(index)
    within ".gl-responsive-table-row:nth-child(#{index + 1})" do
      yield
    end
  end

  def within_environment_spec
    within '.table-section:nth-child(1)' do
      yield
    end
  end

  def within_status
    within '.table-section:nth-child(2)' do
      yield
    end
  end

  def within_delete
    within '.table-section:nth-child(3)' do
      yield
    end
  end
end
