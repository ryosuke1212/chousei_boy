class TempSchedule < ApplicationRecord
  enum status: { title: 0, start_time: 1, completed: 2 }, _default: 0
end
