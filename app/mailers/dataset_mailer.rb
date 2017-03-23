class DatasetMailer < ActionMailer::Base
  default from: "noreply@octopub.io"

  def success(dataset)
    @user = dataset.user
    @dataset = dataset
    if @dataset.github_public?
      template = 'success'
    elsif @dataset.github_private?
      template = 'success_private_github'
    else
      template = 'success_private_local'
    end
    mail(to: @user.email, subject: 'Your Octopub dataset has been created') do |format|
      format.html { render template }
    end
  end

  def error(dataset)
    @user = dataset.user
    @dataset = dataset
    mail(to: @user.email, subject: 'There was a problem creating your Octopub dataset')
  end

end
