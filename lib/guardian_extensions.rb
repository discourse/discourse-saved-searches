# frozen_string_literal: true

module SavedSearches::GuardianExtensions
  def can_use_saved_searches?
    SiteSetting.saved_searches_enabled? && authenticated? &&
      (is_staff? || user.in_any_groups?(SiteSetting.saved_searches_allowed_groups_map))
  end
end
