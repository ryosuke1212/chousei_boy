class ChangeUserIdAndLineGroupIdToStringInSchedules < ActiveRecord::Migration[6.1]
  def change
    change_column :schedules, :user_id, :string
    change_column :schedules, :line_group_id, :string
  end
end
