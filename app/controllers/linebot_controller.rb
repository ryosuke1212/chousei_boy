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
            if event['source']['groupId']
              groupId = event['source']['groupId']
              Schedule.create(line_group_id: groupId)
              message = {
                type: 'text',
                text: '予定を作成しました。'
              }
            elsif event['source']['userId']
              Schedule.create(user_id: event['source']['userId'])
              message = {
                type: 'text',
                text: '予定を作成しました。'
              }
            end
          else
            message = {
              type: 'text',
              text: event.message['text']
            }
          end
        end
      end
      client.reply_message(event['replyToken'], message)
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
end
