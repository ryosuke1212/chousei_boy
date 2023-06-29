class LineGroupsUser < ApplicationRecord
  validates :line_group_id, uniqueness: { scope: :user_id }
  belongs_to :line_group
  belongs_to :user
end