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
    message["action"]["uri"] = "https://chousei-boy-9f11f6556474.herokuapp.com/schedules/#{schedule.url_token}"

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
    message["action"]["uri"] = "https://chousei-boy-9f11f6556474.herokuapp.com/schedules/#{schedule.url_token}"
    # "●いつまでに決める？"部分を削除
    message["body"]["contents"][3]["contents"].delete_at(1)
    # "footer"部分を削除
    message.delete("footer")
    message["styles"].delete("footer")

    message
  end
end
