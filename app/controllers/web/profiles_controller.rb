module Web
  class ProfilesController < ApplicationController
    before_action :set_user

    def edit
      authorize @user, policy_class: ProfilePolicy
    end

    def update
      authorize @user, policy_class: ProfilePolicy
      attributes = profile_params

      if @user.update(attributes)
        bypass_sign_in(@user) if attributes[:password].present?
        redirect_to edit_profile_path, notice: "Profile updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = current_user
    end

    def profile_params
      attributes = params.require(:user).permit(profile_policy.permitted_attributes)
      return attributes unless attributes[:password].blank?

      attributes.except(:password, :password_confirmation)
    end

    def profile_policy
      @profile_policy ||= ProfilePolicy.new(current_user, @user)
    end
  end
end
