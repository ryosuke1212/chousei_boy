module LinebotHelper
  def read_flex_message(schedule)
    file_path = Rails.root.join('app', 'messages', 'schedule_create_message.json')
    message = JSON.parse(File.read(file_path))

    message['body']['contents'][0]['contents'][0]['text'] =
      schedule.start_time.present? ? schedule.start_time.strftime('%-m月%-d日%-H時%-M分') : '日時：未登録'
    message['body']['contents'][0]['contents'][1]['text'] =
      schedule.representative.present? ? "代表：#{schedule.representative}" : '-'
    message['body']['contents'][1]['text'] = schedule.title.present? ? schedule.title : 'みんなで決めよう'
    message['body']['contents'][2]['text'] = schedule.location.present? ? schedule.location : '場所：-'
    message['body']['contents'][3]['contents'][0]['contents'][1]['text'] =
      schedule.description.present? ? schedule.description : '-'
    message['body']['contents'][3]['contents'][1]['contents'][1]['text'] =
      schedule.deadline.present? ? schedule.deadline.strftime('%-m月%-d日') : '-'
    message['footer']['contents'][1]['action']['uri'] = "#{ENV['SCHEDULE_EDIT_URL']}#{schedule.url_token}"
    message['action']['uri'] = "#{ENV['SCHEDULE_EDIT_URL']}#{schedule.url_token}"

    message
  end

  def read_flex_message_finalized(schedule)
    file_path = Rails.root.join('app', 'messages', 'schedule_create_message.json')
    message = JSON.parse(File.read(file_path))

    message['body']['contents'][0]['contents'][0]['text'] =
      schedule.start_time.present? ? schedule.start_time.strftime('%-m月%-d日%-H時%-M分') : '日時：未登録'
    message['body']['contents'][0]['contents'][1]['text'] =
      schedule.representative.present? ? "代表：#{schedule.representative}" : '-'
    message['body']['contents'][1]['text'] = schedule.title.present? ? schedule.title : 'みんなで決めよう'
    message['body']['contents'][2]['text'] = schedule.location.present? ? schedule.location : '場所：-'
    message['body']['contents'][3]['contents'][0]['contents'][1]['text'] =
      schedule.description.present? ? schedule.description : '-'
    message['body']['contents'][3]['contents'][1]['contents'][1]['text'] =
      schedule.deadline.present? ? schedule.deadline.strftime('%-m月%-d日') : '-'
    # "●いつまでに決める？"部分を削除
    message['body']['contents'][3]['contents'].delete_at(1)
    # "footer"部分を削除
    message.delete('footer')
    message['styles'].delete('footer')
    # フレックスメッセージのリンク部分を削除
    message.delete('action')

    message
  end

  def choose_representative(event, temp_schedule)
    users = User.joins(:line_groups).where(line_groups: { line_group_id: event['source']['groupId'] })
    guest_users = GuestUser.joins(:line_groups).where(line_groups: { line_group_id: event['source']['groupId'] })
    all_users = users + guest_users
    representative = all_users.sample.name
    temp_schedule.representative = representative
  end

  def deadline_with_start_time(_event, temp_schedule)
    # deadlineを設定する。start_timeが存在する場合はそれを超えないようにする。
    deadline = DateTime.now + 3.days
    message_text = "【#{temp_schedule.start_time.strftime('%-m月%-d日%-H時%-M分')}】だね！代表者と期日も勝手に決めておいたよ！\n今回は#{temp_schedule.representative}さん中心で予定を決めよう！"
    deadline = temp_schedule.start_time - 1.days if temp_schedule.start_time && deadline > temp_schedule.start_time
    # start_timeが今日の日付だった場合、messageを変更し、deadlineを今日の日付にする
    if temp_schedule.start_time.to_date == Date.today
      message_text = "今日の予定！？代表者も決めておいたから早めに決めよう！\n今回は#{temp_schedule.representative}さん中心で決めよう！"
      deadline = DateTime.now
    end
    temp_schedule.deadline = deadline
    temp_schedule.save
    message_text
  end

  def deadline_without_start_time(temp_schedule)
    temp_schedule.deadline = DateTime.now + 3.days
    temp_schedule.save
  end
end
