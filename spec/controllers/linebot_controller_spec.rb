require 'rails_helper'

RSpec.describe LinebotController, type: :controller do
  describe 'POST #callback' do
    let(:line_group) { LineGroup.create(line_group_id: 'dummy_group_id') }
    let!(:schedule) { Schedule.create(line_group_id: line_group.line_group_id, status: 'title') }
    let(:event) do
      {
        'type' => 'message',
        'replyToken' => 'replyToken',
        'source' => {
          'groupId' => line_group.line_group_id,
          'userId' => 'userId'
        },
        'message' => {
          'id' => '325708',
          'type' => 'text',
          'text' => 'Hello, world'
        }
      }
    end
    let(:body) do
      {
        'events' => [event]
      }.to_json
    end

    before do
      request.headers['CONTENT_TYPE'] = 'application/json; charset=UTF-8'

      # Mock the external API call
      allow(Net::HTTP).to receive(:start).and_return(
        double(
          body: { 'displayName' => 'Test User' }.to_json
        )
      )

      post :callback, body:, as: :json
    end

    it 'responds successfully' do
      expect(response).to be_successful
    end

    it 'creates a guest user if user does not exist' do
      expect(GuestUser.find_by(guest_uid: event['source']['userId'])).to be_present
    end

    it 'creates a LineGroupsGuestUser if user does not exist' do
      expect(LineGroupsGuestUser.find_by(guest_user_id: GuestUser.find_by(guest_uid: event['source']['userId']).id)).to be_present
    end
  end
end
