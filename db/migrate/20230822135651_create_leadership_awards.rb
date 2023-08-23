class CreateLeadershipAwards < ActiveRecord::Migration[6.1]
  def change
    create_table :leadership_awards do |t|
      t.references :user, null: false, foreign_key: true
      t.string :award_name
      t.references :schedule, null: false, foreign_key: true

      t.timestamps
    end
  end
end
