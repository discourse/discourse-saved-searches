# frozen_string_literal: true

Fabricator(:saved_search) do
  user
  query Fabricate.sequence(:query) { |i| "query #{i}" }
  frequency SavedSearch.frequencies[:immediately]
end
