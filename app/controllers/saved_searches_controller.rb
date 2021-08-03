# frozen_string_literal: true

class SavedSearches::SavedSearchesController < ApplicationController
  requires_plugin 'discourse-saved-searches'

  def update
    user = fetch_user_from_params
    guardian.ensure_can_edit!(user)

    queries = params[:searches] || []
    raise Discourse::InvalidParameters.new(:searches) if !queries.is_a?(Array)

    queries = queries
      .map { |q| q.strip.presence }
      .uniq
      .compact
      .first(SiteSetting.max_saved_searches)

    SavedSearch.transaction do
      # Delete saved searches that no longer exist
      user.saved_searches.where.not(query: queries).destroy_all

      # Create new saved searches
      (queries - user.saved_searches.pluck(:query)).each do |query|
        user.saved_searches.create(query: query)
      end
    end

    render json: success_json
  end
end
