# frozen_string_literal: true

class CreateSavedSearchesTables < ActiveRecord::Migration[6.1]
  def change
    create_table :saved_searches do |t|
      t.integer :user_id, null: false
      t.string :query, null: false
      t.string :compiled_query
      t.integer :last_post_id, null: false
      t.datetime :last_searched_at, null: false
      t.timestamps

      t.index :user_id
    end

    execute <<~SQL
      INSERT INTO saved_searches(user_id, query, last_post_id, last_searched_at, created_at, updated_at)
      SELECT ucf1.user_id,
             json_array_elements_text(ucf1.value::json->'searches'),
             COALESCE(ucf2.value::integer, 0),
             ucf2.updated_at,
             ucf1.created_at,
             ucf1.updated_at
      FROM user_custom_fields ucf1
      LEFT JOIN user_custom_fields ucf2 ON ucf1.user_id = ucf2.user_id
      WHERE ucf1.name = 'saved_searches' AND
            ucf2.name = 'saved_searches_min_post_id'
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
