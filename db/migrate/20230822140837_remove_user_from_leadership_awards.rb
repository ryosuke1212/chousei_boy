class RemoveUserFromLeadershipAwards < ActiveRecord::Migration[6.1]
  def change
    remove_reference :leadership_awards, :user, null: false, foreign_key: true
  end
end
