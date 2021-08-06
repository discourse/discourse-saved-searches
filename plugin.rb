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
  require File.expand_path('../app/jobs/regular/execute_saved_searches.rb', __FILE__)
  require File.expand_path('../app/jobs/scheduled/schedule_saved_searches.rb', __FILE__)
  require File.expand_path('../app/models/saved_search_result.rb', __FILE__)
  require File.expand_path('../app/models/saved_search.rb', __FILE__)
  require File.expand_path('../lib/email_user_extensions.rb', __FILE__)
  require File.expand_path('../lib/guardian_extensions.rb', __FILE__)
  require File.expand_path('../lib/user_extensions.rb', __FILE__)
  require File.expand_path('../lib/user_notifications_extensions.rb', __FILE__)

  NotificationEmailer::EmailUser.class_eval { prepend EmailUserExtensions }
  Guardian.class_eval { prepend GuardianExtensions }
  User.class_eval { prepend UserExtensions }
  UserNotifications.class_eval { prepend UserNotificationsExtensions }

  Search.advanced_filter(/^min-post-id:(.*)$/i) do |posts, match|
    if @opts[:saved_search] && id = match.to_i
      posts.where("posts.id > ?", id)
    else
      posts
    end
  end

  Search.advanced_filter(/^min-created-at:(.*)$/i) do |posts, match|
    if @opts[:saved_search] && created_at = match.to_datetime
      posts.where("posts.created_at > ?", created_at)
    else
      posts
    end
  end

  add_to_serializer(:user, :can_use_saved_searches, false) do
    true
  end

  add_to_serializer(:user, :include_can_use_saved_searches?) do
    scope.can_use_saved_searches?
  end

  add_to_serializer(:user, :saved_searches, false) do
    object.saved_searches.pluck(:query)
  end

  add_to_serializer(:user, :include_saved_searches?) do
    scope.can_use_saved_searches? && scope.can_edit?(object)
  end

  SavedSearches::Engine.routes.draw do
    put '/u/:username/preferences/saved-searches' => 'saved_searches#update', constraints: { username: RouteFormat.username }
  end

  Discourse::Application.routes.prepend do
    mount ::SavedSearches::Engine, at: '/'
  end

  Discourse::Application.routes.append do
    get '/u/:username/preferences/saved-searches' => 'users#preferences', constraints: { username: RouteFormat.username }
  end
end
