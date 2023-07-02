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
          text: "「#{schedule.title}」を皆で決めよう！"
        }
    #   flex_message = {
    #       type: 'flex',
    #       altText: 'メッセージを送信しました',
    #       contents: read_flex_message(schedule)
    #     }
      Rails.logger.info "Message: #{message}"
      # client.push_message(schedule.line_group_id, [message, flex_message])
    end
  end
end
