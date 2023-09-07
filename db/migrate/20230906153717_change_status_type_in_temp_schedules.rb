class ChangeStatusTypeInTempSchedules < ActiveRecord::Migration[6.1]
  def up
    change_column :temp_schedules, :status, :integer, using: 'status::integer', default: 0
  end

  def down
    change_column :temp_schedules, :status, :string
  end
end
