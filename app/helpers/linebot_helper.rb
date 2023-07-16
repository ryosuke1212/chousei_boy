module LinebotHelper
  def read_flex_message(schedule)
    file_path = Rails.root.join('app', 'messages', 'schedule_create_message.json')
    message = JSON.parse(File.read(file_path))
    
    message["body"]["contents"][0]["contents"][0]["text"] = schedule.start_time.present? ? schedule.start_time.strftime("%-m月%-d日%-H時%-M分") : "日時：未登録"
    message["body"]["contents"][0]["contents"][1]["text"] = schedule.representative.present? ? "代表：#{schedule.representative}" : "-"
    message["body"]["contents"][1]["text"] = schedule.title.present? ? schedule.title : "みんなで決めよう"
    message["body"]["contents"][2]["text"] = schedule.location.present? ? schedule.location : "場所：-"
    message["body"]["contents"][3]["contents"][0]["contents"][1]["text"] = schedule.description.present? ? schedule.description : "-"
    message["body"]["contents"][3]["contents"][1]["contents"][1]["text"] = schedule.deadline.present? ? schedule.deadline.strftime("%-m月%-d日") : "-"
    message["action"]["uri"] = "https://sorosorokimeyo-b9a94739722d.herokuapp.com/schedules/#{schedule.url_token}"

    message
  end

  def read_flex_message_finalized(schedule)
    file_path = Rails.root.join('app', 'messages', 'schedule_create_message.json')
    message = JSON.parse(File.read(file_path))
    
    message["body"]["contents"][0]["contents"][0]["text"] = schedule.start_time.present? ? schedule.start_time.strftime("%-m月%-d日%-H時%-M分") : "日時：未登録"
    message["body"]["contents"][0]["contents"][1]["text"] = schedule.representative.present? ? "代表：#{schedule.representative}" : "-"
    message["body"]["contents"][1]["text"] = schedule.title.present? ? schedule.title : "みんなで決めよう"
    message["body"]["contents"][2]["text"] = schedule.location.present? ? schedule.location : "場所：-"
    message["body"]["contents"][3]["contents"][0]["contents"][1]["text"] = schedule.description.present? ? schedule.description : "-"
    message["body"]["contents"][3]["contents"][1]["contents"][1]["text"] = schedule.deadline.present? ? schedule.deadline.strftime("%-m月%-d日") : "-"
    message["action"]["uri"] = "https://sorosorokimeyo-b9a94739722d.herokuapp.com/schedules/#{schedule.url_token}"
    # "●いつまでに決める？"部分を削除
    message["body"]["contents"][3]["contents"].delete_at(1)
    # "footer"部分を削除
    message.delete("footer")
    message["styles"].delete("footer")

    message
  end

  def choose_representative(event, schedule)
    users = User.joins(:line_groups).where(line_groups: { line_group_id: event['source']['groupId'] })
    guest_users = GuestUser.joins(:line_groups).where(line_groups: { line_group_id: event['source']['groupId'] })
    all_users = users + guest_users
    representative = all_users.sample.name
    schedule.representative = representative
  end

  def set_deadline_with_start_time(event, schedule)
    # deadlineを設定する。start_timeが存在する場合はそれを超えないようにする。
    deadline = DateTime.now + 3.days
    message_text = "【#{schedule.start_time.strftime("%-m月%-d日%-H時%-M分")}】だね！代表者と期日も勝手に決めておいたよ！\n今回は#{schedule.representative}さん中心で予定を決めよう！"
    if schedule.start_time && deadline > schedule.start_time
      deadline = schedule.start_time - 1.days
    end
    # start_timeが今日の日付だった場合、messageを変更し、deadlineを今日の日付にする
    if schedule.start_time.to_date == Date.today
      message_text = "今日の予定！？代表者も決めておいたから早めに決めよう！\n今回は#{schedule.representative}さん中心で決めよう！"
      deadline = DateTime.now
    end
    schedule.deadline = deadline
    schedule.save
    message_text
  end

  def set_deadline_without_start_time(schedule)
    schedule.deadline = DateTime.now + 3.days
    schedule.save
  end
end
