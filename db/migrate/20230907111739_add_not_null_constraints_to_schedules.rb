class AddNotNullConstraintsToSchedules < ActiveRecord::Migration[6.1]
  def change
    change_column_null :schedules, :title, false
    change_column_null :schedules, :deadline, false
    change_column_null :schedules, :representative, false
  end
end
