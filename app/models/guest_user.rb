class GuestUser < ApplicationRecord
  has_and_belongs_to_many :line_groups, join_table: :line_groups_guest_users

  def name
    guest_name
  end
end
