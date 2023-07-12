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
        line_group = LineGroup.find_or_create_by(line_group_id: event['source']['groupId'])
        message_1 = {
          type: 'text',
          text: 'こんにちは！グループに追加してくれてありがとう！'
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
            else
              # ゲストユーザーを作る
              guest_user = GuestUser.find_or_create_by(guest_uid: event['source']['userId'])
              line_group_guest_user = LineGroupsGuestUser.find_or_create_by(line_group_id: line_group.id, guest_user_id: guest_user.id)
              # ゲストユーザーの名前を取得し保存する
              uri = URI.parse("https://api.line.me/v2/bot/group/#{line_group.line_group_id}/member/#{guest_user.guest_uid}")
              request = Net::HTTP::Get.new(uri)
              request["Authorization"] = "Bearer #{ENV["LINE_CHANNEL_TOKEN"]}"
              req_options = {
                use_ssl: uri.scheme == "https",
              }
              response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
                http.request(request)
              end
              user_profile = JSON.parse(response.body)
              guest_user.update(guest_name: user_profile["displayName"])
            end
          end
          if schedule = Schedule.find_by(line_group_id: event['source']['groupId'])
            if schedule.status == "created_status"
              if event.message['text'] == "未定"
                #代表者をランダムで選ぶ
                group_id = event['source']['groupId']
                users = User.joins(:line_groups).where(line_groups: { line_group_id: group_id })
                guest_users = GuestUser.joins(:line_groups).where(line_groups: { line_group_id: group_id })
                all_users = users + guest_users
                representative = all_users.sample.name
                schedule.representative = representative
                # deadlineを設定する。start_timeが存在する場合はそれを超えないようにする。
                schedule.deadline = DateTime.now + 3.days
                schedule.save
                schedule.update(status: 3)
                message = {
                  type: 'text',
                  text: "まだ日程は決まってないね！3日後までに決めちゃおう！代表者も勝手に決めちゃったよ！\n#{schedule.representative}さんよろしく！"
                }
                flex_message = {
                  type: 'flex',
                  altText: 'メッセージを送信しました',
                  contents: read_flex_message(schedule)
                }
                client.reply_message(event['replyToken'], [message, flex_message])
              end
            end

            if schedule.status == "datetime_status"
              if event.message['text'] == "未定"
                message = {
                  type: 'text',
                  text: "まだ決まってないね！これから決めていこう！\n日程を次のボタンで教えてね！決まってなかったら「未定」とチャットで教えてね！"
                }
                schedule.title = "何するかはこれから決めよう"
              else
                schedule.title = event.message['text']
                schedule.save
                message = {
                  type: 'text',
                  text: "【#{event.message['text']}】だね！\n日程を次のボタンで教えてね！決まってなかったら「未定」とチャットで教えてね！"
                }
              end
              flex_message = {
                type: 'flex',
                altText: 'メッセージを送信しました',
                contents: choose_datetime
              }
              schedule.update(status: 2)
              client.reply_message(event['replyToken'], [message, flex_message])
            end
          end
          case event.message['text']
          when '予定を削除'
            schedule = Schedule.find_by(line_group_id: event['source']['groupId'])
            if schedule
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
          when '予定を確定'
            schedule = Schedule.find_by(line_group_id: event['source']['groupId'])
            if schedule
              message = {
                type: 'text',
                text: '予定決められて偉い！また予定立ちそうになったら呼んでね！'
              }
              flex_message_1 = {
                type: 'flex',
                altText: 'メッセージを送信しました',
                contents: read_flex_message_finalized(schedule)
              }
              flex_message_2 = {
                type: 'flex',
                altText: 'メッセージを送信しました',
                contents: join_message
              }
              schedule.destroy
              client.reply_message(event['replyToken'], [message, flex_message_1, flex_message_2])
            end
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
              #代表者をランダムで選ぶ
              group_id = event['source']['groupId']
              users = User.joins(:line_groups).where(line_groups: { line_group_id: group_id })
              guest_users = GuestUser.joins(:line_groups).where(line_groups: { line_group_id: group_id })
              all_users = users + guest_users
              representative = all_users.sample.name
              schedule.representative = representative
              # deadlineを設定する。start_timeが存在する場合はそれを超えないようにする。
              deadline = DateTime.now + 3.days
              message_text = "【#{schedule.start_time.strftime("%-m月%-d日%-H時%-M分")}】だね！代表者と期日も勝手に決めておいたから早めに決めよう！\n#{schedule.representative}さんよろしく！"
              if schedule.start_time && deadline > schedule.start_time
                deadline = schedule.start_time - 1.days
              end
              # start_timeが今日の日付だった場合、messageを変更し、deadlineを今日の日付にする
              if schedule.start_time.to_date == Date.today
                message_text = "今日の予定！？代表者も決めておいたから早めに決めよう！\n#{schedule.representative}さんよろしく！"
                deadline = DateTime.now
              end
              schedule.deadline = deadline
              schedule.save
              schedule.update(status: 3)
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
          end
        end

        if event['postback']['data'] == 'send_message_from_bot'
          if schedule = Schedule.find_by(line_group_id: event['source']['groupId'])
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

  def join_message
    file_path = Rails.root.join('app', 'messages', 'join_message.json')
    message = JSON.parse(File.read(file_path))
  end

  def choose_datetime
    file_path = Rails.root.join('app', 'messages', 'choose_datetime.json')
    message = JSON.parse(File.read(file_path))
  end

  def create_action(event)
    groupId = event['source']['groupId']
    if schedule = Schedule.find_by(line_group_id: groupId)
      @response = "まだ決まっていない予定があるからそっちから決めよう！"
      return
    else
      schedule = Schedule.create(line_group_id: groupId, status: 'title_status', url_token: generate_unique_url_token)
      @response = "何をするか決まってる？タイトルを教えてね！（例. 遊び・旅行・飲み会など）\n決まってなければ「未定」と入力してね！"
      schedule.update(status: 1)
    end
  end

  def generate_unique_url_token
    loop do
      url_token = SecureRandom.hex(10)
      return url_token unless Schedule.exists?(url_token: url_token)
    end
  end
end