module JoinEventHandler
  extend ActiveSupport::Concern

  def handle_join_event(event)
    LineGroup.find_or_create_by(line_group_id: event['source']['groupId'])
    message1 = {
      type: 'text',
      text: 'こんにちは！グループに追加してくれてありがとう！'
    }
    message2 = {
      type: 'text',
      text: '仲良い人同士だと予定の詳細決めナマけちゃうことあるよね！'
    }
    message3 = {
      type: 'text',
      text: "なまけちゃいそうな予定が立ったら決まってることだけ見える化しておこう！！\n（※返信に時間がかかる場合があります）"
    }
    flex_message = {
      type: 'flex',
      altText: 'メッセージを送信しました',
      contents: join_message
    }
    client.reply_message(event['replyToken'], [message1, message2, message3, flex_message])
  end
end
