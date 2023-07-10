class CreateLineGroupsGuestUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :line_groups_guest_users do |t|
      t.references :line_group, null: false, foreign_key: true
      t.references :guest_user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
