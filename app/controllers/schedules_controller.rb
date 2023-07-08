class SchedulesController < ApplicationController
  def index
    user_schedules = Schedule.where(user_id: current_user.uid)
    line_group_ids = current_user.line_groups.pluck(:line_group_id)
    group_schedules = Schedule.where(line_group_id: line_group_ids)
    @schedules = user_schedules.or(group_schedules)
  end

  def create
    @schedule = Schedule.new(title: "未登録", start_time: "未登録", end_time: "未登録", representative: "未登録", location: "未登録", description: "未登録", deadline: "未登録")
    @schedule.save
    redirect_to schedules_path, notice: "予定を登録しました" 
  end

  def show
    @schedule = Schedule.find_by(url_token: params[:url_token])
  end

  def destroy
    @schedule = Schedule.find_by(url_token: params[:url_token])
    @schedule.destroy
    redirect_to schedules_path, notice: "予定が削除されました。"
  end

  def edit
    @schedule = Schedule.find_by(url_token: params[:url_token])
  end

  def update
    @schedule = Schedule.find_by(url_token: params[:url_token])
    start_time = schedule_params[:start_time].blank? ? nil : Time.zone.parse(schedule_params[:start_time])
    end_time = schedule_params[:end_time].blank? ? nil : Time.zone.parse(schedule_params[:end_time])
    deadline = schedule_params[:deadline].blank? ? nil : Time.zone.parse(schedule_params[:deadline])
    if @schedule.update(schedule_params.merge(start_time: start_time, end_time: end_time, deadline: deadline))
    redirect_to schedules_path, flash: { success: '編集したよ！botに通知させるにはbotの「通知」を押してね！' }
    else
      render :edit
    end
  end

  private

  def schedule_params
    params.require(:schedule).permit(:title, :start_time, :end_time, :representative, :location, :description, :deadline)
  end

end
