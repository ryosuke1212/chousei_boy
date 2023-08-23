class AddLeadershipawardToSchedules < ActiveRecord::Migration[6.1]
  def change
    add_column :schedules, :leadership_award, :string
  end
end
