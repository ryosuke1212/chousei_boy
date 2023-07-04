class LineGroupsGuestUser < ApplicationRecord
  validates :line_group_id, uniqueness: { scope: :guest_user_id }
  belongs_to :line_group
  belongs_to :guest_user
end
