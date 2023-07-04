class CreateGuestUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :guest_users do |t|
      t.string :guest_uid, null: false, index: { unique: true }
      t.string :guest_name

      t.timestamps
    end
  end
end
