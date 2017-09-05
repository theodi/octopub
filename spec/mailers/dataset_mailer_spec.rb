require 'rails_helper'

RSpec.describe DatasetMailer, type: :mailer do
  describe 'sending' do

    context 'success' do
      let(:dataset) { build(:dataset) }
      let(:mail) { described_class.success(dataset).deliver_now }

      it 'renders the subject' do
        expect(mail.subject).to eq('Your Octopub dataset has been created')
      end

      it 'renders the receiver email' do
        expect(mail.to).to eq([dataset.user.email])
      end

      it 'renders the sender email' do
        expect(mail.from).to eq(["noreply@octopub.io"])
      end

      it 'contains the link to the github pages' do
        expect(mail.body.encoded).to match("#{dataset.gh_pages_url}")
      end
    end

    context 'success github private' do
      let(:dataset) { build(:dataset, publishing_method: :github_private) }
      let(:mail) { described_class.success(dataset).deliver_now }

      it 'renders the subject' do
        expect(mail.subject).to eq('Your Octopub dataset has been created')
      end

      it 'renders the receiver email' do
        expect(mail.to).to eq([dataset.user.email])
      end

      it 'renders the sender email' do
        expect(mail.from).to eq(["noreply@octopub.io"])
      end

      it 'does not contain the link to the github pages' do
        expect(mail.body.encoded).to_not match("#{dataset.gh_pages_url}")
      end

      it 'does contain the link to the github repository' do
        expect(mail.body.encoded).to match("#{dataset.github_url}")
      end

      it "does indicate a private repository in GitHub in the message" do
        expect(mail.body.encoded).to match("has been created as a private repository in GitHub")
      end
    end

    context 'success local private' do
      let(:dataset) { build(:dataset, publishing_method: :local_private, id: 1) }
      let(:mail) { described_class.success(dataset).deliver_now }

      it 'renders the subject' do
        expect(mail.subject).to eq('Your Octopub dataset has been created')
      end

      it 'renders the receiver email' do
        expect(mail.to).to eq([dataset.user.email])
      end

      it 'renders the sender email' do
        expect(mail.from).to eq(["noreply@octopub.io"])
      end

      it 'does not contain the link to the github pages' do
        expect(mail.body.encoded).to_not match("#{dataset.gh_pages_url}")
      end

      it 'does contain the link to the dataset page in octopub' do
        expect(mail.body.encoded).to match("#{dataset_url(dataset)}")
      end

      it 'does not contain the link to the github repository' do
        expect(mail.body.encoded).to_not match("#{dataset.github_url}")
      end

      it "does indicate a private repository in Octopub in the message" do
        expect(mail.body.encoded).to match("has been created as a private repository in Octopub")
      end
    end
  end
end

