# frozen_string_literal: true

class SavedSearches::SavedSearchesController < ApplicationController
  requires_plugin 'discourse-saved-searches'

  def update
    if params[:searches]
      current_user.custom_fields['saved_searches'] = { "searches" => params[:searches] }
      current_user.save
    else
      UserCustomField.where(name: 'saved_searches', user_id: current_user.id).first&.destroy
    end

    render json: success_json
  end
end
