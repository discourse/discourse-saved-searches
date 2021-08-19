# frozen_string_literal: true

module SavedSearches::GuardianExtensions
  def can_use_saved_searches?
    SiteSetting.saved_searches_enabled? && (is_staff? || user.has_trust_level?(SiteSetting.saved_searches_min_trust_level))
  end
end
