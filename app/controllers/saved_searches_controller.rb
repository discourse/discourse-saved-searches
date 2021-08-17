# frozen_string_literal: true

class SavedSearches::SavedSearchesController < ApplicationController
  requires_plugin 'discourse-saved-searches'

  def update
    user = fetch_user_from_params
    guardian.ensure_can_edit!(user)

    searches = []
    params[:searches].each do |_, search|
      raise Discourse::InvalidParameters.new(:query) if search[:query].blank?
      raise Discourse::InvalidParameters.new(:frequency) if search[:frequency].blank?

      query = search[:query].strip.presence
      raise Discourse::InvalidParameters.new(:query) if query.blank?

      frequency = SavedSearch.frequencies[search[:frequency].to_sym]
      raise Discourse::InvalidParameters.new(:frequency) if frequency.blank?

      searches << { query: query, frequency: frequency }
    end
    searches = searches.uniq { |s| s[:query] }
    raise Discourse::InvalidParameters.new(:searches) if searches.size > SiteSetting.max_saved_searches

    SavedSearch.transaction do
      # Delete saved searches that no longer exist
      user.saved_searches.where.not(query: searches.map { |s| s[:query] }).destroy_all

      # Create new saved searches
      searches.each do |search|
        saved_search = user.saved_searches.find_or_initialize_by(query: search[:query])
        saved_search.update!(frequency: search[:frequency])
      end
    end

    render json: success_json
  end
end
