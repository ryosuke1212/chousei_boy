class LinebotController < ApplicationController
  require 'line/bot'
  include LinebotHelper
  include JoinEventHandler
  include MessageEventHandler
  include PostbackEventHandler

  def callback
    body = request.body.read
    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Join
        handle_join_event(event)
      when Line::Bot::Event::Message
        handle_message_event(event)
      when Line::Bot::Event::Postback
        handle_postback_event(event)
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
    temp_schedule = TempSchedule.find_by(line_group_id: groupId)
    if Schedule.find_by(line_group_id: groupId)
      @response = "まだ決め切ってない予定があるみたい。予定の「確定」ボタンか「削除」ボタンで新しい予定を作成できるよ！\nそれかチャット欄で「予定を確定」「予定を削除」と教えてね！"
    elsif temp_schedule && temp_schedule.status == 'title'
      @response = "タイトル入力待ちの予定があるよ！何するか決まってる？遊び？飲み会？\n入力して教えて☆\n決まってなければ「未定」でもいいよ！"
    elsif temp_schedule && temp_schedule.status == 'start_time'
      @response = "日程入力待ちの予定があるよ！いつの予定かは決めてる？🕐\n決まってなかったら「未定」とチャットで教えてね！"
    else
      temp_schedule = TempSchedule.create(line_group_id: groupId, status: 'title')
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
