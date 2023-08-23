class DropLeadershipAwards < ActiveRecord::Migration[6.1]
  def change
    drop_table :leadership_awards
  end
end
