# frozen_string_literal: true

module SavedSearches::EmailUserExtensions
  def custom
    if @notification.data_hash[:saved_search_id].present?
      enqueue :saved_search
    else
      super if defined?(super)
    end
  end
end
