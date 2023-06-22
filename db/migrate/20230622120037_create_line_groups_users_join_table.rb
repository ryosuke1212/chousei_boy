class CreateLineGroupsUsersJoinTable < ActiveRecord::Migration[6.1]
  def change
    create_join_table :line_groups, :users do |t|
    end
  end
end
