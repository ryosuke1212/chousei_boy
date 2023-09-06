class RenamePendingSchedulesToTempSchedules < ActiveRecord::Migration[6.1]
  def change
    rename_table :pending_schedules, :temp_schedules
  end
end
