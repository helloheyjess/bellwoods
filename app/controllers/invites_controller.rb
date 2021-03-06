class InvitesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_invite, only: [:show, :destroy]

  def index
    @invites = Invite.where(user_id: current_user.id).order(created_at: :desc)
    @profile = current_user.profile
  end

  def new
    @invite = Invite.new
    @invite_id = SecureRandom.random_number(1_000_000_000)
    @profile = current_user.profile

    js :avatar => ActionController::Base.helpers.asset_path(@profile.avatar.url(:marker))
  end

  def create
  	@invite = Invite.create(invite_params)
    @invite.user_id = current_user.id
    @profile = current_user.profile

  	if @invite.save
      InvitesEmailJob.new.async.perform(@invite)
      redirect_to invite_path(@invite)
      flash[:notice] = "Invite Email has been sent!"
    else
      render :new
      flash[:notice] = "Oh no! An error!"
    end
  end

  def show
    @profile = @invite.user.profile

    js :avatar => ActionController::Base.helpers.asset_path(@invite.user.profile.avatar.url(:marker))

    if @invite.created_at > 4.hours.ago
      if !current_user.nil? && current_user.id == @invite.user_id
          render :show
      end
    else
      @invite.destroy
      redirect_to pages_expired_path, notice: 'Invite is expired and has been destroyed'
    end
  end

  def destroy
    @invite.destroy
    redirect_to invites_path, notice: 'Invite has been destroyed'
  end

private
	
	def set_invite
		@invite = Invite.find_by_id(params[:id])
    redirect_to pages_expired_path unless @invite
	end

	def invite_params
		params.require(:invite).permit(:id, :message, :recipient, :user_id, :latitude, :longitude, :expire_time)
	end
  
end
