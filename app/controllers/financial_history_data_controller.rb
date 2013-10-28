class FinancialHistoryDataController < ApplicationController

  # GET /financial_history_data
  def index
    @financial_history_data = FinancialHistoryData.all
    @user = User.new
    @users = User.all
    @day_change = FinancialHistoryData.daily_change_hash

    @chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(:style => {color: '#666', fontFamily: 'Roboto', fontSize: '12px', fontWeight: '100', letterSpacing: '2px'})
      f.xAxis(:categories => FinancialHistoryData.prepare_entry_dates_for_chart, :labels => {enabled: false})
      f.series(:name => "DIA (SPDR 1x DJIA ETF)", :yAxis => 1, :color => '#777', :dashStyle => 'ShortDot', :lineWidth => 2, :marker => {:symbol => 'triangle-down', :radius => 3}, :data => FinancialHistoryData.prepare_data_for_chart('dia_last'))
      f.series(:name => "Investor Sentiment", :yAxis => 0, :color => '#3487FF', :dashStyle => 'ShortDot', :lineWidth => 2, :marker => {:symbol => 'triangle-down', :radius => 3}, :data => FinancialHistoryData.prepare_investor_data_for_chart)
      f.series(:name => "Media Sentiment", :yAxis => 0, :color => '#ff1a29', :dashStyle => 'ShortDot', :lineWidth => 2, :marker => {:symbol => 'triangle-down', :radius => 3}, :data => FinancialHistoryData.prepare_media_data_for_chart)

      f.yAxis [
        { :title => {:text => "Raw Sentiment Score", :margin => 20, :margin => 30, :style => {:color => '#666', :font_family => 'Roboto', :font_size => '14px', :font_weight => '400', :letter_spacing => '2px'}}, :lineWidth => 1, :lineColor => '#ff1a29', :opposite => true, :gridLineColor => '#EEE', :showFirstLabel => false, :tickPixelInterval => 75, :labels => {:style => {:color => '#666', :font_family => 'Roboto', :font_size => '12px', :font_weight => '300', :letter_spacing => '1px'}}, :offset => 20, :tickLength => 10, :tickWidth => 1, :tickColor => '#ff1a29', :tickPosition => 'inside'},

        { :title => {:text => "DIA Market Price ($)", :margin => 30, :style => {:color => '#666', :font_family => 'Roboto', :font_size => '14px', :font_weight => '400', :letter_spacing => '2px'}}, :lineWidth => 1, :lineColor => '#ff1a29', :gridLineColor => '#EEE', :showFirstLabel => false, :tickPixelInterval => 75, :labels => {:format => '${value}', :style => {:color => '#666', :font_family => 'Roboto', :font_size => '12px', :font_weight => '300', :letter_spacing => '1px'}}, :offset => 20, :tickLength => 10, :tickWidth => 1, :tickColor => '#ff1a29', :tickPosition => 'inside'}
      ]

      f.xAxis [
        {:lineWidth => 1, :lineColor => '#EEE', :labels => {:enabled => false}, :tickWidth => 0, :categories => FinancialHistoryData.prepare_entry_dates_for_chart}
      ]

      f.legend(:enabled => true, :borderWidth => 0, :align => 'center', :itemDistance => 40, :itemMarginTop => 10, :style => {:color => '#EEE', :font_family => 'Roboto', :font_size => '12px', :font_weight => '300', :letter_spacing => '1px'})
      f.chart({:defaultSeriesType=>"line", :marginLeft => 150, :marginRight => 150})

      f.tooltip(:style => {fontFamily: 'Roboto'}, :shared => true, :valueDecimals => 2)
    end


      @chart2 = LazyHighCharts::HighChart.new('pie') do |f|
        f.chart({:defaultSeriesType=>"pie" , :margin=> [50, 60, 0, 60]} )
        series = {
         :type=> 'pie',
         :name=> 'Sentiment Breakdown',
         :data=> [
                {:name=> 'Positive', :y=> FinancialHistoryData.prepare_count_data_for_pie_chart[:positive], :color=> 'green'}, 
                {:name=> 'Neutral', :y=> FinancialHistoryData.prepare_count_data_for_pie_chart[:neutral], :color=> '#CCC'},
                {:name=> 'Negative', :y=> FinancialHistoryData.prepare_count_data_for_pie_chart[:negative], :color=> '#ff1a29'}
              ]}
      f.series(series)
      f.tooltip(:style => {font_family: 'Roboto', font_size: 14, color: '#333'}, :shared => true, :valueDecimals => 2)
      f.plot_options( :pie => {
        :allowPointSelect => true, 
        :cursor => "pointer", 
        :dataLabels => {
          :enabled => true,
          :distance => 60,
          :connectorPadding => 20,
          :style => {
            :font_size => 16,
            :font_family => 'Roboto',
            :font_weight => 300,
            :color => '#666',
            :letter_spacing => '1px',
            :text_transform => 'uppercase',
          }
        }
         })
      end


  end



  private

    def financial_history_data_params
      params.require(:financial_history_data).permit(:date, :djia_delta, :sp_delta, :twitter_score, :media_score, :investor_score)
    end
end
