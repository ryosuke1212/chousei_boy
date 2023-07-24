class GuestUser < ApplicationRecord
  has_and_belongs_to_many :line_groups, join_table: :line_groups_guest_users

  def name
    guest_name
  end

  def self.find_or_create_with_line_profile!(user_id, line_group_id)
    guest_user = find_by(guest_uid: user_id)
    if guest_user.nil?
      guest_user = create!(guest_uid: user_id)
      # ゲストユーザーの名前を取得し保存する
      uri = URI.parse("https://api.line.me/v2/bot/group/#{line_group_id}/member/#{user_id}")
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{ENV['LINE_CHANNEL_TOKEN']}"
      req_options = {
        use_ssl: uri.scheme == 'https'
      }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      user_profile = JSON.parse(response.body)
      guest_user.update!(guest_name: user_profile['displayName'])
    end
    LineGroupsGuestUser.find_or_create_by!(line_group_id:, guest_user_id: guest_user.id)
  end
end
