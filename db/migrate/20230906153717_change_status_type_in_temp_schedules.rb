class ChangeStatusTypeInTempSchedules < ActiveRecord::Migration[6.1]
  def change
    change_column :temp_schedules, :status, :integer, default: 0
  end
end
