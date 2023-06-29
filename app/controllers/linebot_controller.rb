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
      when Line::Bot::Event::Join
        line_group = LineGroup.find_or_create_by(line_group_id: event['source']['groupId'])
        message_1 = {
          type: 'text',
          text: 'こんにちは！グループに追加してくれてありがとう！私は予定調整botの調整ボーイです！'
        }
        message_2 = {
          type: 'text',
          text: '会う約束をしたけど「何するか決まらない」「日程が決まらない」なんてことありませんか？何が決まっていないか明確にしておきましょう！予定が立ったら次のボタンで予定を作成しましょう！'
        }
        flex_message = {
          type: 'flex',
          altText: 'メッセージを送信しました',
          contents: join_message
        }
        client.reply_message(event['replyToken'], [message_1, message_2, flex_message])
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if event['source']['groupId']
            line_group = LineGroup.find_or_create_by(line_group_id: event['source']['groupId'])
            user = User.find_by(uid: event['source']['userId'])
            if user
              line_group_user = LineGroupsUser.find_or_create_by(line_group: line_group, user: user)
            end
          end
          if schedule = Schedule.find_by(line_group_id: event['source']['groupId'])
            if schedule && schedule.status == "datetime_status"
              schedule.title = event.message['text']
              schedule.save
              schedule.update(status: 2)
              message = {
                type: 'text',
                text: "#{event.message['text']}だね！次は日程を教えてね！"
              }
              flex_message = {
                type: 'flex',
                altText: 'メッセージを送信しました',
                contents: choose_datetime
              }
              client.reply_message(event['replyToken'], [message, flex_message])
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
          elsif event.message['text'] == '予定を削除'
            schedule = Schedule.find_by(line_group_id: event['source']['groupId'])
              if schedule
                schedule.destroy
                message = {
                  type: 'text',
                  text: '予定を削除しました！'
                }
                client.reply_message(event['replyToken'], message)
              end
          else
            message = {
              type: 'text',
              text: event.message['text']
            }
            client.reply_message(event['replyToken'], message)
          end
        end
      when Line::Bot::Event::Postback
        if event['postback']['data'] == 'create_schedule_in_group'
          create_action(event)
          message = {
            type: 'text',
            text: @response
          }
          client.reply_message(event['replyToken'], message)
        end

        if event['postback']['data'] == 'choose_schedule_date'
          if schedule = Schedule.find_by(line_group_id: event['source']['groupId'])
            if schedule && schedule.status == "created_status"
              datetime_param = params["events"][0]["postback"]["params"]["datetime"]
              start_time = DateTime.parse(datetime_param).strftime("%Y-%m-%d %H:%M:%S")
              schedule.start_time = start_time
              schedule.save
              schedule.update(status: 3)
              message = {
                type: 'text',
                text: "#{start_time}だね！予定を組んだよ！"
              }
              flex_message = {
                type: 'flex',
                altText: 'メッセージを送信しました',
                contents: read_flex_message(schedule)
              }
              client.reply_message(event['replyToken'], [message, flex_message])
            end
          end
        end

        if event['postback']['data'] == 'send_message_from_bot'
          if schedule = Schedule.find_by(line_group_id: event['source']['groupId'])
            message = {
                type: 'text',
                text: "まだ決まってない予定があるよ！皆で決めよう！"
              }
            flex_message = {
                type: 'flex',
                altText: 'メッセージを送信しました',
                contents: read_flex_message(schedule)
              }
            client.reply_message(event['replyToken'], [message, flex_message])
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

  def join_message
    file_path = Rails.root.join('app', 'messages', 'join_message.json')
    message = JSON.parse(File.read(file_path))
  end

  def choose_datetime
    file_path = Rails.root.join('app', 'messages', 'choose_datetime.json')
    message = JSON.parse(File.read(file_path))
  end

  def create_action(event)
    if event['source']['groupId']
      groupId = event['source']['groupId']
      existing_schedule = Schedule.find_by(line_group_id: groupId)
      if existing_schedule
        @response = "まだ決まっていない予定があるからそっちから決めよう！"
        return
      end
      schedule = Schedule.create(line_group_id: groupId, status: 'title_status')
    elsif event['source']['userId']
      schedule = Schedule.create(user_id: event['source']['userId'], status: :title_status)
    end

    if schedule
      case schedule.status
      when "title_status"
        @response = "やることは決まってる？"
        schedule.update(status: 1)
      end
    end
  end
end