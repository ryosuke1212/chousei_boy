class AddStatusToSchedules < ActiveRecord::Migration[6.1]
  def change
    add_column :schedules, :status, :integer
  end
end
