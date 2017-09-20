class Ability
  include CanCan::Ability

  def initialize(user)
    if user && !user.guest?
      # A user can manage their datasets
      can :manage, Dataset, :user => user
      # and their schemas
      can :manage, DatasetFileSchema, :user => user
      # # Admins can do everything
      if user.admin?
        can :manage, Dataset
      end
    end
    # Everyone can read public datasets
    can :read, Dataset, publishing_method: "github_public"
    # and public schemas
    can :read, DatasetFileSchema, restricted: false
  end
end
