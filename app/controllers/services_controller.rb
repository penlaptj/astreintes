class ServicesController < ApplicationController
  # Seuls les administrateurs créent et gèrent les services.
  before_action :require_admin
  before_action :set_service, only: %i[edit update destroy]

  def index
    @services = Service.order(:name)
  end

  def new
    @service = Service.new
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      redirect_to services_path, notice: "Service « #{@service.name} » créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @service.update(service_params)
      redirect_to services_path, notice: "Service mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy
    redirect_to services_path, notice: "Service supprimé."
  end

  private

  def set_service
    @service = Service.find(params[:id])
  end

  def service_params
    params.require(:service).permit(:name, :description)
  end
end
