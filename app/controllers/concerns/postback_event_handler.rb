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
       (temp_schedule = TempSchedule.find_by(line_group_id: event['source']['groupId'])) &&
       (temp_schedule && temp_schedule.status == 'start_time')
      datetime_param = extract_date_from_postback_params(params)
      start_time = DateTime.parse(datetime_param).strftime('%Y-%m-%d')
      temp_schedule.start_time = start_time
      choose_representative(event, temp_schedule)
      message_text = deadline_with_start_time(event, temp_schedule)
      schedule = Schedule.create(
        title: temp_schedule.title,
        start_time: temp_schedule.start_time,
        representative: temp_schedule.representative,
        deadline: temp_schedule.deadline,
        line_group_id: temp_schedule.line_group_id,
        url_token: generate_unique_url_token,
        status: 2
      )
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
