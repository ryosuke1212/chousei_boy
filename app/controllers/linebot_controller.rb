class LinebotController < ApplicationController
  require 'line/bot'
  include LinebotHelper

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
        LineGroup.find_or_create_by(line_group_id: event['source']['groupId'])
        message1 = {
          type: 'text',
          text: 'こんにちは！グループに追加してくれてありがとう！'
        }
        message2 = {
          type: 'text',
          text: '仲良い人同士だと予定の詳細決めナマけちゃうことあるよね！'
        }
        message3 = {
          type: 'text',
          text: "なまけちゃいそうな予定が立ったら決まってることだけ見える化しておこう！！\n（※返信に時間がかかる場合があります）"
        }
        flex_message = {
          type: 'flex',
          altText: 'メッセージを送信しました',
          contents: join_message
        }
        client.reply_message(event['replyToken'], [message1, message2, message3, flex_message])
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          line_group = LineGroup.find_by(line_group_id: event['source']['groupId'])
          schedule = Schedule.find_by(line_group_id: event['source']['groupId'])
          if (user = User.find_by(uid: event['source']['userId']))
            LineGroupsUser.find_or_create_by(line_group:, user:)
          else
            GuestUser.find_or_create_with_line_profile!(event['source']['userId'], line_group.id)
          end
          if schedule.status == 'title'
            if event.message['text'] == '未定'
              message = {
                type: 'text',
                text: "予定なんてそんなもんよね！これから決めてこ！\n流石にいつの予定かは決めてるよね？決まってなければ「未定」でも良いよ！"
              }
              schedule.title = '何するかはこれから決めよう'
            else
              schedule.title = event.message['text']
              schedule.save
              message = {
                type: 'text',
                text: "【#{event.message['text']}】だね！\nいつの予定かは決めてる？🕐\n決まってなかったら「未定」とチャットで教えてね！"
              }
            end
            flex_message = {
              type: 'flex',
              altText: 'メッセージを送信しました',
              contents: choose_datetime
            }
            schedule.update(status: 1)
            client.reply_message(event['replyToken'], [message, flex_message])
          elsif schedule.status == 'start_time'
            if event.message['text'] == '未定'
              choose_representative(event, schedule)
              deadline_without_start_time(schedule)
              schedule.update(status: 2)
              message = {
                type: 'text',
                text: "まだ日程は決まってないね！サクッと3日後までに決めちゃおう！\n今回は#{schedule.representative}さん中心で決めよう！"
              }
              flex_message = {
                type: 'flex',
                altText: 'メッセージを送信しました',
                contents: read_flex_message(schedule)
              }
              client.reply_message(event['replyToken'], [message, flex_message])
            end
          end
          if event.message['text'] == '予定を削除'
            schedule.destroy
            message = {
              type: 'text',
              text: '予定を削除しました！また予定立ててね！'
            }
            flex_message = {
              type: 'flex',
              altText: 'メッセージを送信しました',
              contents: join_message
            }
            client.reply_message(event['replyToken'], [message, flex_message])
          end
          if event.message['text'] == '予定を確定'
            message = {
              type: 'text',
              text: '予定決められて偉い！また予定立ちそうになったら呼んでね！'
            }
            flex_message1 = {
              type: 'flex',
              altText: 'メッセージを送信しました',
              contents: read_flex_message_finalized(schedule)
            }
            flex_message2 = {
              type: 'flex',
              altText: 'メッセージを送信しました',
              contents: join_message
            }
            schedule.destroy
            client.reply_message(event['replyToken'], [message, flex_message1, flex_message2])
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
        if event['postback']['data'] == 'choose_schedule_date' &&
           (schedule = Schedule.find_by(line_group_id: event['source']['groupId'])) &&
           (schedule && schedule.status == 'start_time')
          datetime_param = extract_date_from_postback_params(params)
          start_time = DateTime.parse(datetime_param).strftime('%Y-%m-%d')
          schedule.start_time = start_time
          choose_representative(event, schedule)
          message_text = deadline_with_start_time(event, schedule)
          schedule.update(status: 2)
          message = {
            type: 'text',
            text: message_text
          }
          flex_message = {
            type: 'flex',
            altText: 'メッセージを送信しました',
            contents: read_flex_message(schedule)
          }
          client.reply_message(event['replyToken'], [message, flex_message])
        end
        if event['postback']['data'] == 'send_message_from_bot' &&
           (schedule = Schedule.find_by(line_group_id: event['source']['groupId']))
          message = {
            type: 'text',
            text: "#{schedule.representative}さん！\nまだ決まってない予定があるよ！皆で決めよう！"
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
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end

  def join_message
    file_path = Rails.root.join('app', 'messages', 'join_message.json')
    JSON.parse(File.read(file_path))
  end

  def choose_datetime
    file_path = Rails.root.join('app', 'messages', 'choose_datetime.json')
    JSON.parse(File.read(file_path))
  end

  def create_action(event)
    groupId = event['source']['groupId']
    if Schedule.find_by(line_group_id: groupId)
      @response = "まだ決め切ってない予定があるみたい。予定の「確定」ボタンか「削除」ボタンで新しい予定を作成できるよ！\nそれかチャット欄で「予定を確定」「予定を削除」と教えてね！"
    else
      Schedule.create(line_group_id: groupId, status: 'title', url_token: generate_unique_url_token)
      @response = "何するか決まってる？遊び？飲み会？\n入力して教えて☆\n決まってなければ「未定」でもいいよ！"
    end
  end

  def extract_date_from_postback_params(params)
    params['events'][0]['postback']['params']['date']
  end

  def generate_unique_url_token
    loop do
      url_token = SecureRandom.hex(10)
      return url_token unless Schedule.exists?(url_token:)
    end
  end
end
