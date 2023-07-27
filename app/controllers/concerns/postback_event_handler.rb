module PostbackEventHandler
  extend ActiveSupport::Concern

  def handle_postback_event(event)
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
