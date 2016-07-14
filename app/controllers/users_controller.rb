class UsersController < ApplicationController

  before_filter :check_signed_in?, only: [:edit, :update]

  def new
  end

  def edit
  end

  private

    def check_signed_in?
      render_403 if current_user.nil?
    end
end
