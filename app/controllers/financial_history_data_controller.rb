class FinancialHistoryDataController < ApplicationController
  # before_action :set_financial_history_data, only: [:show, :edit, :update, :destroy]

  # GET /financial_history_data
  def index
    FinancialHistoryData.prepare_investor_data_for_chart
    @financial_history_data = FinancialHistoryData.all
    @user = User.new

    @chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(:text => "Financial Market Sentiment")
      f.xAxis(:categories => FinancialHistoryData.prepare_entry_dates_for_chart, :labels => {enabled: false})
      f.series(:name => "DIA", :yAxis => 1, :data => FinancialHistoryData.prepare_data_for_chart('dia_last'))
      f.series(:name => "SPY", :yAxis => 1, :data => FinancialHistoryData.prepare_data_for_chart('spy_last'))
      f.series(:name => "Investor Sentiment", :yAxis => 0, :data => FinancialHistoryData.prepare_investor_data_for_chart)
      f.series(:name => "Media Sentiment", :yAxis => 0, :data => FinancialHistoryData.prepare_media_data_for_chart)

      f.yAxis [
        {:title => {:text => "Raw Sentiment Score", :margin => 70} },
        {:title => {:text => "DIA & SPY Market Price"}, :opposite => true},
      ]

      f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
      f.chart({:defaultSeriesType=>"line"})
    end

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
