# frozen_string_literal: true

class SavedSearchSerializer < ApplicationSerializer
  attributes :query, :frequency

  def frequency
    SavedSearch.frequencies[object.frequency]
  end
end
