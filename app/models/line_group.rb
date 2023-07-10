class LineGroup < ApplicationRecord
  has_and_belongs_to_many :users
  has_and_belongs_to_many :guest_users, join_table: :line_groups_guest_users
end
