class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :read, :update, :destroy, to: :crud

    if user
      # There might be a better idiom for this, but this will do for now.

      # Things everyone logged in can do go here

      # Editors and above
      if user.editor? || user.publisher? || user.superuser? || user.admin?
        # Editors can view and edit their existing datasets
        # Publishers will create datasets and assign them to editors
        can [:read, :update, :dashboard, :user_datasets], Dataset, user: user
      end

      # Publishers and above
      if user.publisher? || user.superuser? || user.admin?
        # Publishers can do everything to their datasets including make new ones
        can :manage, Dataset, user: user
        # and their schemas
        can :manage, DatasetFileSchema, user: user
      end

      # Superusers and above
      if user.superuser? || user.admin?
        # Currently unsure of what the superuser role is for, so this is blank
      end

      # Admins only
      if user.admin?
        # Admins can do everything
        can :manage, :all
      end

    end
    # Everyone can read public datasets
    can :read, Dataset, publishing_method: "github_public"
    # and public schemas
    can :read, DatasetFileSchema, restricted: false
  end
end
