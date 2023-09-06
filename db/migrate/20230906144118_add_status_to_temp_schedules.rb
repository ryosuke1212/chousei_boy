class AddStatusToTempSchedules < ActiveRecord::Migration[6.1]
  def change
    add_column :temp_schedules, :status, :string
  end
end
