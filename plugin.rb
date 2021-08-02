# frozen_string_literal: true

# name: discourse-saved-searches
# about: Saved Searches Plugin
# version: 0.1
# authors: Neil Lalonde
# url: https://github.com/discourse/discourse-saved-searches
# transpile_js: true

enabled_site_setting :saved_searches_enabled

register_asset 'stylesheets/saved-searches.scss'

after_initialize do
  module ::SavedSearches
    class Engine < ::Rails::Engine
      engine_name 'saved_searches'
      isolate_namespace SavedSearches
    end
  end

  require File.expand_path('../app/controllers/saved_searches_controller.rb', __FILE__)
  require File.expand_path('../app/jobs/regular/saved_search_notification.rb', __FILE__)
  require File.expand_path('../app/jobs/scheduled/schedule_saved_searches.rb', __FILE__)
  require File.expand_path('../lib/guardian_extensions.rb', __FILE__)

  Guardian.class_eval { prepend GuardianExtensions }

  add_to_serializer(:user, :can_use_saved_searches, false) do
    true
  end

  add_to_serializer(:user, :include_can_use_saved_searches?) do
    scope.can_use_saved_searches?
  end

  add_to_serializer(:user, :saved_searches, false) do
    object.custom_fields.dig('saved_searches', 'searches')
  end

  add_to_serializer(:user, :include_saved_searches?) do
    scope.can_use_saved_searches? && scope.can_edit?(object)
  end

  User.register_custom_field_type('saved_searches', :json)

  SavedSearches::Engine.routes.draw do
    resource :saved_searches, only: [:update]
  end

  Discourse::Application.routes.prepend do
    mount ::SavedSearches::Engine, at: '/'
  end

  Discourse::Application.routes.append do
    get '/u/:username/preferences/saved-searches' => 'users#preferences', constraints: { username: RouteFormat.username }
  end
end
