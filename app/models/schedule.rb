class Schedule < ApplicationRecord
  validates_uniqueness_of :line_group_id
  enum status: { title: 0, start_time: 1, completed: 2 }, _default: 0
  attribute :url_token, :string, default: SecureRandom.hex(10)
  validates :url_token, presence: true, uniqueness: true
  validates :title, presence: true
  validates :deadline, presence: true
  validates :representative, presence: true

  def to_param
    url_token
  end

  def self.assign_award(schedule)
    time_difference = Time.now - schedule.created_at

    award_name = case time_difference
                 when 0..(24 * 3600) then '決断の神'
                 when (24 * 3600 + 1)..(3 * 24 * 3600) then '決断名人'
                 end

    schedule.update(leadership_award: award_name) if award_name
    award_name
  end
end
