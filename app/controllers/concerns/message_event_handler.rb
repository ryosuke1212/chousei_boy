module MessageEventHandler
  extend ActiveSupport::Concern

  def handle_message_event(event)
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
        if event.message['text'] =~ /未定|みてい|ミテイ/
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
        if event.message['text'] =~ /未定|みてい|ミテイ/
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
  end
end
