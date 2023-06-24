class LinebotController < ApplicationController
  require 'line/bot'

  def callback
    body = request.body.read
    # signature = request.env['HTTP_X_LINE_SIGNATURE']
    # unless client.validate_signature(body, signature)
    #   error 400 do 'Bad Request' end
    # end
    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          # LINEグループとユーザーを紐付ける
          if event['source']['groupId'] && event['source']['userId']
            line_group_id = event['source']['groupId']
            user_id = event['source']['userId']
            user = User.find_by(uid: user_id)
            if user
              line_group = LineGroup.find_or_create_by(line_group_id: line_group_id)
              LineGroupsUser.create(line_group_id: line_group.id, user_id: user.id)
            end
          end

          if event.message['text'] == '予定作成'
            schedule = nil
            if event['source']['groupId']
              groupId = event['source']['groupId']
              schedule = Schedule.create(line_group_id: groupId)
            elsif event['source']['userId']
              schedule = Schedule.create(user_id: event['source']['userId'])
            end

            if schedule
              message = {
                type: 'text',
                text: '予定を作成しました。'
              }
              flex_message = {
                type: 'flex',
                altText: 'メッセージを送信しました',
                contents: read_flex_message(schedule)
              }
              client.reply_message(event['replyToken'], [message, flex_message])
            end

          elsif event.message['text'] == '予定一覧'
            user_id = event['source']['userId']
            schedules = Schedule.where(user_id: user_id)
            schedules.each do |schedule|
              message = {
                type: 'text',
                text: '予定一覧です'
              }
              flex_message = {
                type: 'flex',
                altText: 'メッセージを送信しました',
                contents: read_flex_message(schedule)
              }
              client.reply_message(event['replyToken'], [message, flex_message])
            end
            message = {
              type: 'text',
              text: event.message['text']
            }
            client.reply_message(event['replyToken'], message)
          end
        end
      end
    end
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def read_flex_message(schedule)
    file_path = Rails.root.join('app', 'messages', 'schedule_create_message.json')
    message = JSON.parse(File.read(file_path))

    message["body"]["contents"][0]["text"] = schedule.start_time.to_s if schedule.start_time
    message["body"]["contents"][1]["text"] = schedule.title.to_s if schedule.title
    message["body"]["contents"][2]["text"] = schedule.location.to_s if schedule.location
    message["body"]["contents"][4]["contents"][0]["contents"][1]["text"] = schedule.description.to_s if schedule.description
    message["body"]["contents"][4]["contents"][1]["contents"][1]["text"] = schedule.representative.to_s if schedule.representative
    message["body"]["contents"][4]["contents"][2]["contents"][1]["text"] = schedule.deadline.to_s if schedule.deadline

    message
  end
end
