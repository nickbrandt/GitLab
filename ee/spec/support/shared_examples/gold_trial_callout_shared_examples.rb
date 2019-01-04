# frozen_string_literal: true

shared_examples 'gold trial callout' do
  before do
    sign_in(user)
  end

  it 'hides promotion callout if not .com' do
    allow(Gitlab).to receive(:com?).and_return(false)

    visit page_path

    expect(page).not_to have_selector '.promotion-callout'
  end

  context '.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    it 'shows dismissable promotion callout if default dashboard', :js do
      allow_any_instance_of(EE::DashboardHelper).to receive(:user_default_dashboard?).and_return(true)

      visit page_path

      expect(page).to have_selector '.promotion-callout'

      find('.js-close').click

      expect(page).not_to have_selector '.promotion-callout'
    end

    it 'hides dismissable promotion callout if not default dashboard', :js do
      allow_any_instance_of(EE::DashboardHelper).to receive(:user_default_dashboard?).and_return(false)

      visit page_path

      expect(page).not_to have_selector '.promotion-callout'
    end

    it 'hides promotion callout if a trial is active' do
      group = create(:group, name: 'trial group', trial_ends_on: 1.year.from_now)
      group.add_owner(user)

      visit page_path

      expect(page).not_to have_selector '.promotion-callout'
    end

    it 'hides promotion callout if a gold plan is active', :js do
      group = create(:group, name: 'gold group', plan: :gold_plan)
      group.add_owner(user)

      visit page_path

      expect(page).not_to have_selector '.promotion-callout'
    end
  end
end
