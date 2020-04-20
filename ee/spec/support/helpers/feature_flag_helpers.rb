# frozen_string_literal: true

module FeatureFlagHelpers
  def create_flag(project, name, active = true, description: nil, version: Operations::FeatureFlag.versions['legacy_flag'])
    create(:operations_feature_flag, name: name, active: active, version: version,
                                     description: description, project: project)
  end

  def create_scope(feature_flag, environment_scope, active = true, strategies = [{ name: "default", parameters: {} }])
    create(:operations_feature_flag_scope,
      feature_flag: feature_flag,
      environment_scope: environment_scope,
      active: active,
      strategies: strategies)
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

  def within_strategy_row(index)
    within ".feature-flags-form > fieldset > div:nth-child(#{index + 3})" do
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
    within '.table-section:nth-child(4)' do
      yield
    end
  end

  def edit_feature_flag_button
    find('.js-feature-flag-edit-button')
  end

  def expect_user_to_see_feature_flags_index_page
    expect(page).to have_css('h3.page-title', text: 'Feature Flags')
    expect(page).to have_text('All')
    expect(page).to have_text('Enabled')
    expect(page).to have_text('Disabled')
  end
end
