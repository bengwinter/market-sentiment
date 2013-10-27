class FinancialHistoryDataController < ApplicationController
  # before_action :set_financial_history_data, only: [:show, :edit, :update, :destroy]

  # GET /financial_history_data
  def index
    @financial_history_data = FinancialHistoryData.all
    @user = User.new
    @users = User.all

    @chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.xAxis(:categories => FinancialHistoryData.prepare_entry_dates_for_chart, :labels => {enabled: false})
      f.series(:name => "DIA (SPDR 1x DJIA ETF)", :yAxis => 1, :color => '#ff1a29', :dashStyle => 'ShortDot', :lineWidth => 3, :marker => {:symbol => 'triangle-down'}, :data => FinancialHistoryData.prepare_data_for_chart('dia_last'))
      f.series(:name => "Investor Sentiment", :yAxis => 0, :data => FinancialHistoryData.prepare_investor_data_for_chart)
      f.series(:name => "Media Sentiment", :yAxis => 0, :data => FinancialHistoryData.prepare_media_data_for_chart)
      f.series(:type=> 'pie',:name=> "Today's Sentiment Breakdown", 
            :data=> [
              {:name=> 'Positive', :y=> FinancialHistoryData.prepare_count_data_for_pie_chart[:positive], :color=> 'green'}, 
              {:name=> 'Neutral', :y=> FinancialHistoryData.prepare_count_data_for_pie_chart[:neutral], :color=> 'gray'},
              {:name=> 'Negative', :y=> FinancialHistoryData.prepare_count_data_for_pie_chart[:negative], :color=> 'red'}
            ],
            :center=> [80,10], :size=> 100, :showInLegend=> false)

      f.yAxis [
        {:title => {:text => "Raw Sentiment Score", :margin => 20}, :opposite => true },
        {:title => {:text => "DIA Market Price", :margin => 20}}
      ]

      f.legend(:enabled => false)
      f.chart({:defaultSeriesType=>"line", :marginLeft => 150, :marginRight => 150})
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
