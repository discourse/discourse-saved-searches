# frozen_string_literal: true

class CreateSavedSearchesTables < ActiveRecord::Migration[6.1]
  def change
    create_table :saved_searches do |t|
      t.integer :user_id
      t.string :query, null: false
      t.string :compiled_query
      t.timestamps

      t.index :user_id
    end

    execute <<~SQL
      INSERT INTO saved_searches(user_id, query, created_at, updated_at)
      SELECT user_id,
             json_array_elements_text(value::json->'searches') query,
             created_at,
             updated_at
      FROM user_custom_fields
      WHERE name = 'saved_searches'
    SQL

    create_table :saved_search_results do |t|
      t.integer :saved_search_id, null: false
      t.integer :post_id, null: false
      t.integer :notification_id
      t.timestamps

      t.index :post_id
    end
  end
end
