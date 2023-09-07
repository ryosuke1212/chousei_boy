module MessageEventHandler
  extend ActiveSupport::Concern

  def handle_message_event(event)
    case event.type
    when Line::Bot::Event::MessageType::Text
      line_group = LineGroup.find_by(line_group_id: event['source']['groupId'])
      temp_schedule = TempSchedule.find_by(line_group_id: event['source']['groupId'])
      schedule = Schedule.find_by(line_group_id: event['source']['groupId'])
      if (user = User.find_by(uid: event['source']['userId']))
        LineGroupsUser.find_or_create_by(line_group:, user:)
      else
        GuestUser.find_or_create_with_line_profile!(event['source']['userId'], line_group.id)
      end
      if temp_schedule && temp_schedule.status == 'title'
        if event.message['text'] == '予定を確定' || event.message['text'] == '予定を削除'
          message = {
            type: 'text',
            text: "タイトル入力待ちだよ！何するか決まってる？遊び？飲み会？\n入力して教えて☆\n決まってなければ「未定」でもいいよ！"
          }
          client.reply_message(event['replyToken'], [message])
          return
        elsif event.message['text'] =~ /未定|みてい|ミテイ/
          message = {
            type: 'text',
            text: "予定なんてそんなもんよね！これから決めてこ！\n流石にいつの予定かは決めてるよね？決まってなければ「未定」でも良いよ！"
          }
          temp_schedule.title = '何するかはこれから決めよう'
        else
          temp_schedule.title = event.message['text']
          temp_schedule.save
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
        temp_schedule.update(status: 1)
        client.reply_message(event['replyToken'], [message, flex_message])
      elsif  temp_schedule && temp_schedule.status == 'start_time'
        if event.message['text'] =~ /未定|みてい|ミテイ/
          choose_representative(event, temp_schedule)
          deadline_without_start_time(temp_schedule)
          schedule = Schedule.create(
            title: temp_schedule.title,
            start_time: temp_schedule.start_time,
            representative: temp_schedule.representative,
            deadline: temp_schedule.deadline,
            line_group_id: temp_schedule.line_group_id,
            url_token: generate_unique_url_token,
            status: 2
          )
          temp_schedule.destroy
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
        # 予定を決めるのにかかった時間に応じて称号を付与
        award_name = Schedule.assign_award(schedule)
        message_text = if award_name
                         comment = award_name == '決断の神' ? 'めちゃくちゃ予定決めるの早かったね！' : '予定決めるの上手だね！'
                         "#{comment}#{schedule.representative}さんは「#{award_name}」だよ！\nまた予定立ちそうになったら呼んでね！"
                       else
                         '予定決められて偉い！また予定立ちそうになったら呼んでね！'
                       end
        message = {
          type: 'text',
          text: message_text
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
