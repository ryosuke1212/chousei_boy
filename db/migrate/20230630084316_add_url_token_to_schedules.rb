class AddUrlTokenToSchedules < ActiveRecord::Migration[6.1]
  def change
    add_column :schedules, :url_token, :string
  end
end
