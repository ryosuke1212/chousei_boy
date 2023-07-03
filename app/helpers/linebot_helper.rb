module LinebotHelper
  def read_flex_message(schedule)
  file_path = Rails.root.join('app', 'messages', 'schedule_create_message.json')
  message = JSON.parse(File.read(file_path))
  message["body"]["contents"][0]["text"] = schedule.start_time.present? ? schedule.start_time.strftime("%-m月%-d日%-H時%-M分") : "日時：未登録"
  message["body"]["contents"][1]["text"] = schedule.title.present? ? schedule.title : "タイトル：未登録"
  message["body"]["contents"][2]["text"] = schedule.location.present? ? schedule.location : "場所：未登録"
  message["body"]["contents"][4]["contents"][0]["contents"][1]["text"] = schedule.description.present? ? schedule.description : "未登録"
  message["body"]["contents"][4]["contents"][1]["contents"][1]["text"] = schedule.representative.present? ? schedule.representative : "未登録"
  message["body"]["contents"][4]["contents"][2]["contents"][1]["text"] = schedule.deadline.present? ? schedule.deadline.to_s : "未登録"
  message["body"]["contents"][6]["contents"][0]["action"]["uri"] = "http://localhost:3000/schedules/#{schedule.url_token}"
  message
  end
end
