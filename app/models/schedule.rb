class Schedule < ApplicationRecord
  validates_uniqueness_of :line_group_id
  enum status: { title_status: 0, datetime_status: 1, created_status: 2, complete: 3 }, _default: 0
end