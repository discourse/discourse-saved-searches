# frozen_string_literal: true

# name: discourse-saved-searches
# about: Saved Searches Plugin
# version: 0.1
# authors: Neil Lalonde
# url: https://github.com/discourse/discourse-saved-searches
# transpile_js: true

enabled_site_setting :saved_searches_enabled

register_asset "stylesheets/saved-searches.scss"

after_initialize do
  module ::SavedSearches
    class Engine < ::Rails::Engine
      engine_name "saved_searches"
      isolate_namespace SavedSearches
    end
  end

  require_relative "app/controllers/saved_searches_controller.rb"
  require_relative "app/jobs/regular/execute_saved_searches.rb"
  require_relative "app/jobs/scheduled/schedule_saved_searches.rb"
  require_relative "app/models/saved_search_result.rb"
  require_relative "app/models/saved_search.rb"
  require_relative "app/serializers/saved_search_serializer.rb"
  require_relative "lib/email_user_extensions.rb"
  require_relative "lib/guardian_extensions.rb"
  require_relative "lib/user_extensions.rb"
  require_relative "lib/user_notifications_extensions.rb"

  reloadable_patch do
    NotificationEmailer::EmailUser.class_eval { prepend SavedSearches::EmailUserExtensions }
    Guardian.class_eval { prepend SavedSearches::GuardianExtensions }
    User.class_eval { prepend SavedSearches::UserExtensions }
    UserNotifications.class_eval { prepend SavedSearches::UserNotificationsExtensions }
  end

  register_search_advanced_filter(/^min-post-id:(.*)$/i) do |posts, match|
    if @opts[:saved_search] && id = match.to_i
      posts.where("posts.id > ?", id)
    else
      posts
    end
  end

  register_search_advanced_filter(/^min-created-at:(.*)$/i) do |posts, match|
    if @opts[:saved_search] && created_at = match.to_datetime
      posts.where("posts.created_at > ?", created_at)
    else
      posts
    end
  end

  add_to_serializer(:user, :can_use_saved_searches, false) { true }

  add_to_serializer(:user, :include_can_use_saved_searches?) { scope.can_use_saved_searches? }

  add_to_serializer(:user, :saved_searches, false) do
    ActiveModel::ArraySerializer.new(
      object.saved_searches,
      each_serializer: SavedSearchSerializer,
      scope: scope,
    ).as_json
  end

  add_to_serializer(:user, :include_saved_searches?) do
    scope.can_use_saved_searches? && scope.can_edit?(object)
  end

  SavedSearches::Engine.routes.draw do
    put "/u/:username/preferences/saved-searches" => "saved_searches#update",
        :constraints => {
          username: RouteFormat.username,
        }
  end

  Discourse::Application.routes.prepend { mount ::SavedSearches::Engine, at: "/" }

  Discourse::Application.routes.append do
    get "/u/:username/preferences/saved-searches" => "users#preferences",
        :constraints => {
          username: RouteFormat.username,
        }
  end
end
