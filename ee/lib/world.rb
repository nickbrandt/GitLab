# frozen_string_literal: true

module World
  include ::Gitlab::Utils::StrongMemoize
  extend self

  DENYLIST = ['Iran (Islamic Republic of)', 'Sudan', 'Syrian Arab Republic', 'Korea (Democratic People\'s Republic of)', 'Cuba'].freeze

  def countries_for_select
    strong_memoize(:countries_for_select) { all_countries.sort_by(&:name).map { |c| [c.name, c.alpha2] } }
  end

  def all_countries
    strong_memoize(:all_countries) { ISO3166::Country.all.reject {|item| DENYLIST.include?(item.name) } }
  end
end
