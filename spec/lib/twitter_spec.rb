describe TwitterNotifier do
  context 'with no twitter handle and an email preference' do
    it 'tweets: 0, emails: 1' do
      @user = create :user
      @dataset = create :dataset, name: 'This one should not Tweet', user_id: @user.id 

      expect(TwitterNotifier).to_not receive(:success).with(@dataset, @user)
      expect(DatasetMailer).to receive(:success) {
        messager = double(Mail::Message)
        expect(messager).to receive(:deliver)
        messager
      }
      @dataset.send(:send_success_message)
    end
  end

  context 'with a twitter handle but an email preference' do
    it 'tweets: 0, emails: 1' do
      @user = create :user, twitter_handle: 'pikesley', notification_preference: 'email'
      @dataset = create :dataset, name: 'This one should not Tweet', user_id: @user.id

      expect(TwitterNotifier).to_not receive(:success).with(@dataset, @user)
      expect(DatasetMailer).to receive(:success) {
        messager = double(Mail::Message)
        expect(messager).to receive(:deliver)
        messager
      }
      @dataset.send(:send_success_message)
    end
  end

  context 'with no twitter handle but a twitter preference' do
    it 'tweets: 0, emails: 1' do
      @user = create :user, notification_preference: 'twitter'
      @dataset = create :dataset, name: 'This one should not Tweet', user_id: @user.id

      expect(TwitterNotifier).to_not receive(:success).with(@dataset, @user)
      expect(DatasetMailer).to receive(:success) {
        messager = double(Mail::Message)
        expect(messager).to receive(:deliver)
        messager
      }
      @dataset.send(:send_success_message)
    end
  end

  context 'with a twitter handle and a twitter preference' do
    it 'tweets: 1, emails: 0' do
      @user = create :user, twitter_handle: 'pikesley', notification_preference: 'twitter'
      @dataset = create :dataset, name: 'This one should Tweet', user_id: @user.id

      expect(TwitterNotifier).to receive(:success).with(@dataset, @user)
      expect(DatasetMailer).to_not receive(:success)
      @dataset.send(:send_success_message)
    end
  end
end
