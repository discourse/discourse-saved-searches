# frozen_string_literal: true

module SavedSearches::UserExtensions
  def self.prepended(base)
    base.has_many :saved_searches
  end
end
