class SchedulesController < ApplicationController
  def index
    @schedules = Schedule.all
  end

  def create
    @schedule = Schedule.new(title: "未登録", start_time: "未登録", end_time: "未登録", representative: "未登録", location: "未登録", description: "未登録", deadline: "未登録")
    @schedule.save
    redirect_to schedules_path, notice: "予定を登録しました" 
  end

  def destroy
    @schedule = Schedule.find(params[:id])
    @schedule.destroy
    redirect_to schedules_path, notice: "予定が削除されました。"
  end

  def edit
    @schedule = Schedule.find(params[:id])
  end

  def update
    @schedule = Schedule.find(params[:id])
    if @schedule.update(schedule_params)
      redirect_to schedules_path, notice: '予定が更新されました。'
    else
      render :edit
    end
  end

  private

  def schedule_params
    params.require(:schedule).permit(:title, :start_time, :end_time, :representative, :location, :description, :deadline)
  end

end
