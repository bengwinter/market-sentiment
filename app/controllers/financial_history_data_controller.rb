class FinancialHistoryDataController < ApplicationController
  # before_action :set_financial_history_data, only: [:show, :edit, :update, :destroy]

  # GET /financial_history_data
  def index
    @financial_history_data = FinancialHistoryData.all
    @data_new = FinancialHistoryData.new
    # @data_new.update_database
  end

  # # GET /financial_history_data/1
  # def show
  # end

  # GET /financial_history_data/new
  # def new
  #   @financial_history_data = FinancialHistoryData.new
  # end

  # # GET /financial_history_data/1/edit
  # def edit
  # end

  # POST /financial_history_data
  # def create
  #   @financial_history_data = FinancialHistoryData.new(financial_history_data_params)

  #   respond_to do |format|
  #     if @financial_history_data.save
  #       format.html { redirect_to @financial_history_data, notice: 'Datapoints were successfully added.' }
  #     else
  #       format.html { render action: 'new' }
  #     end
  #   end
  # end

  # # PATCH/PUT /financial_history_data/1
  # def update
  #   respond_to do |format|
  #     if @financial_history_data.update(financial_history_data_params)
  #       format.html { redirect_to @financial_history_data, notice: 'Datapoints were successfully updated.' }
  #     else
  #       format.html { render action: 'edit' }
  #     end
  #   end
  # end

  # # DELETE /financial_history_data/1
  # def destroy
  #   @financial_history_data.destroy
  #   respond_to do |format|
  #     format.html { redirect_to financial_history_data_url }
  #   end
  # end

  private
    # def set_financial_history_data
    #   @financial_history_data = FinancialHistoryData.find(params[:id])
    # end

    def financial_history_data_params
      params.require(:financial_history_data).permit(:date, :djia_delta, :sp_delta, :twitter_score, :media_score, :investor_score)
    end
end
