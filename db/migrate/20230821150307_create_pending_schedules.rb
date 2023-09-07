class CreatePendingSchedules < ActiveRecord::Migration[6.1]
  def change
    create_table :pending_schedules do |t|
      t.string :title
      t.datetime :start_time
      t.string :representative
      t.datetime :deadline
      t.string :line_group_id, null:false

      t.timestamps
    end
  end
end