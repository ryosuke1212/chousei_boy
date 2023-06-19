class CreateLineGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :line_groups do |t|
      t.string "line_group_id"
      t.string "line_group_name"

      t.timestamps
    end
  end
end
