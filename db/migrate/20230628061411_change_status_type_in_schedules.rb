class ChangeStatusTypeInSchedules < ActiveRecord::Migration[6.1]
  def up
    change_column :schedules, :status, :integer
  end

  def down
    change_column :schedules, :status, :string
  end
end
