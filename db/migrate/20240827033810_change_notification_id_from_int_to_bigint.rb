# frozen_string_literal: true
class ChangeNotificationIdFromIntToBigint < ActiveRecord::Migration[7.1]
  def up
    execute("ALTER TABLE saved_search_results ALTER COLUMN notification_id TYPE bigint")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
