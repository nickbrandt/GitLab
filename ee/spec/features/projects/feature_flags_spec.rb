require 'spec_helper'

describe 'Feature Flags', :js do
  using RSpec::Parameterized::TableSyntax

  invalid_input_table = proc do
    'with space' | '' | 'Name can contain only'
    '<script>' | '' | 'Name can contain only'
    'x' * 100 | '' | 'Name is too long'
    'some-name' | 'y' * 1001 | 'Description is too long'
  end

  let(:user) {create(:user)}
  let(:project) {create(:project, namespace: user.namespace)}

  before do
    stub_licensed_features(feature_flags: true)
    stub_feature_flags(feature_flags_environment_scope: false)
    sign_in(user)
  end

  it 'shows empty state' do
    visit(project_feature_flags_path(project))

    expect_empty_state
  end

  context 'when creating a new feature flag' do
    context 'and input is valid' do
      where(:name, :description, :status) do
        'my-active-flag' | 'a new flag' | true
        'my-inactive-flag' | '' | false
      end

      with_them do
        it 'adds the feature flag to the table' do
          add_feature_flag(name, description, status)

          expect_feature_flag(name, description, status)
          expect(page).to have_selector '.flash-container', text: 'successfully created'
        end
      end
    end

    context 'and input is invalid' do
      where(:name, :description, :error_message, &invalid_input_table)

      with_them do
        it 'displays an error message' do
          add_feature_flag(name, description, false)

          expect(page).to have_selector '.alert-danger', text: error_message
        end
      end
    end
  end

  context 'when editing a feature flag' do
    before do
      add_feature_flag('feature-flag-to-edit', 'with some description', false)
    end

    shared_examples_for 'correct edit behavior' do
      context 'and input is valid' do
        it 'updates the feature flag' do
          name = 'new-name'
          description = 'new description'

          edit_feature_flag('feature-flag-to-edit', name, description, true)

          expect_feature_flag(name, description, true)
          expect(page).to have_selector '.flash-container', text: 'successfully updated'
        end
      end

      context 'and input is invalid' do
        where(:name, :description, :error_message, &invalid_input_table)

        with_them do
          it 'displays an error message' do
            edit_feature_flag('feature-flag-to-edit', name, description, false)

            expect(page).to have_selector '.alert-danger', text: error_message
          end
        end
      end
    end

    it_behaves_like 'correct edit behavior'
  end

  context 'when deleting a feature flag' do
    before do
      add_feature_flag('feature-flag-to-delete', 'with some description', false)
    end

    shared_examples_for 'correct delete behavior' do
      context 'and no feature flags are left' do
        it 'shows empty state' do
          visit(project_feature_flags_path(project))

          delete_feature_flag('feature-flag-to-delete')

          expect_empty_state
        end
      end

      context 'and there is a feature flag left' do
        before do
          add_feature_flag('another-feature-flag', '', true)
        end

        it 'shows feature flag table without deleted feature flag' do
          visit(project_feature_flags_path(project))

          delete_feature_flag('feature-flag-to-delete')

          expect_feature_flag('another-feature-flag', '', true)
        end
      end

      it 'does not delete if modal is cancelled' do
        visit(project_feature_flags_path(project))

        delete_feature_flag('feature-flag-to-delete', false)

        expect_feature_flag('feature-flag-to-delete', 'with some description', false)
      end
    end

    it_behaves_like 'correct delete behavior'
  end

  context 'when user sees empty index page' do
    before do
      visit(project_feature_flags_path(project))
    end

    shared_examples_for 'correct empty index behavior' do
      it 'shows empty state' do
        expect(page).to have_content('Get started with Feature Flags')
        expect(page).to have_link('New Feature Flag')
        expect(page).to have_button('Configure')
      end
    end

    it_behaves_like 'correct empty index behavior'
  end

  context 'when user sees index page' do
    let!(:feature_flag_enabled) { create(:operations_feature_flag, project: project, active: true) }
    let!(:feature_flag_disabled) { create(:operations_feature_flag, project: project, active: false) }

    before do
      visit(project_feature_flags_path(project))
    end

    context 'when user sees all tab' do
      it 'shows all feature flags' do
        expect(page).to have_content(feature_flag_enabled.name)
        expect(page).to have_content(feature_flag_disabled.name)
        expect(page).to have_link('New Feature Flag')
        expect(page).to have_button('Configure')
      end
    end

    context 'when user sees enabled tab' do
      it 'shows only active feature flags' do
        find('.js-featureflags-tab-enabled').click

        expect(page).to have_content(feature_flag_enabled.name)
        expect(page).not_to have_content(feature_flag_disabled.name)
      end
    end

    context 'when user sees disabled tab' do
      it 'shows only inactive feature flags' do
        find('.js-featureflags-tab-disabled').click

        expect(page).not_to have_content(feature_flag_enabled.name)
        expect(page).to have_content(feature_flag_disabled.name)
      end
    end
  end

  private

  def add_feature_flag(name, description, status)
    visit(new_project_feature_flag_path(project))

    fill_in 'Name', with: name
    fill_in 'Description', with: description

    if status
      check('Active')
    else
      uncheck('Active')
    end

    click_button 'Create feature flag'
  end

  def delete_feature_flag(name, confirm = true)
    delete_button = find('.gl-responsive-table-row', text: name).find('.js-feature-flag-delete-button')

    delete_button.click

    within '.modal' do
      if confirm
        click_button 'Delete'
      else
        click_button 'Cancel'
      end
    end
  end

  def edit_feature_flag(old_name, new_name, new_description, new_status)
    visit(project_feature_flags_path(project))

    edit_button = find('.gl-responsive-table-row', text: old_name).find('.js-feature-flag-edit-button')

    edit_button.click

    fill_in 'Name', with: new_name
    fill_in 'Description', with: new_description

    if new_status
      check('Active')
    else
      uncheck('Active')
    end

    click_button 'Save changes'
  end

  def expect_empty_state
    expect(page).to have_selector('.js-feature-flags-empty-state')
    expect(page).to have_selector('.btn-success', text: 'New Feature Flag')
    expect(page).to have_selector('.btn-primary.btn-inverted', text: 'Configure')
  end

  def expect_feature_flag(name, description, status)
    expect(current_path).to eq project_feature_flags_path(project)
    expect(page).to have_selector '.table-section .badge', text: status ? 'Active' : 'Inactive'
    expect(page).to have_selector '.table-section', text: name
    expect(page).to have_selector '.table-section', text: description
  end
end
