class DatasetMailer < ActionMailer::Base
  default from: "noreply@octopub.io"

  def success(dataset)
    @user = dataset.user
    @dataset = dataset
    mail(to: @user.email, subject: 'Your Octopub dataset has been created')
  end

  def error(dataset)
    @user = dataset.user
    @dataset = dataset
    mail(to: @user.email, subject: 'There was a problem creating your Octopub dataset')
  end

end
