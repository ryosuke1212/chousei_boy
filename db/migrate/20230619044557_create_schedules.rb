class CreateSchedules < ActiveRecord::Migration[6.1]
  def change
    create_table :schedules do |t|
      t.string :title
      t.datetime :start_time
      t.datetime :end_time
      t.string :location
      t.string :description
      t.string :representative
      t.datetime :deadline
      t.integer :user_id
      t.integer :line_group_id

      t.timestamps
    end
  end
end
