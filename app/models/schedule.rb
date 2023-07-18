class Schedule < ApplicationRecord
  validates_uniqueness_of :line_group_id
  enum status: { title: 0, start_time: 1, completed: 2 }, _default: 0
  attribute :url_token, :string, default: SecureRandom.hex(10)
  validates :url_token, presence: true, uniqueness: true

  def to_param
    url_token
  end
end
