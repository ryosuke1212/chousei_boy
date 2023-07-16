require_relative '../../app/helpers/linebot_helper'
include LinebotHelper

namespace :schedule_remind do
  desc "予定のリマインド通知を送る"
  task :remind => :environment do
    client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
    Schedule.where("deadline >= ? AND deadline < ?", Date.today, Date.today + 1.day).each do |schedule|
      message = {
          type: 'text',
          text: "今日期限の予定があるよ！そろそろ決めよ！"
        }
      flex_message = {
          type: 'flex',
          altText: 'メッセージを送信しました',
          contents: read_flex_message(schedule)
        }
      client.push_message(schedule.line_group_id, [message, flex_message])
    end
  end
end
