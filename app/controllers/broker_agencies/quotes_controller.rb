class BrokerAgencies::QuotesController < ApplicationController

  include DataTablesAdapter

  before_action :find_quote , :only => [:publish_quote, :view_published_quote]
  before_action :format_date_params  , :only => [:update,:create]
  before_action :set_qhp_variables, :only => [:plan_comparison, :download_pdf]
  before_action :employee_relationship_map

  def view_published_quote

  end

  def publish_quote
    @params = params.inspect

    if @quote.may_publish?

      @quote.plan_option_kind = params[:plan_option_kind].gsub(' ','_').downcase
      @quote.published_reference_plan = Plan.find(params[:reference_plan_id]).id
      @quote.publish
      @quote.save!
    end
    render "publish_quote" , :flash => {:notice => "Quote Published" }
  end

  # displays index page of quotes
  def my_quotes
    @all_quotes = Quote.where("broker_role_id" => current_user.person.broker_role.id)
  end

  def quote_index_datatable
    dt_query = extract_datatable_parameters

    quotes = Quote.where("broker_role_id" => current_user.person.broker_role.id)

    @payload = quotes.map { |q|
      {
        :quote_name => q.quote_name,
        :family_count => q.quote_households.count,
        :benefit_group_count => q.quote_benefit_groups.count,
        :quote_state => q.aasm_state

      }
    }
      @draw = dt_query.draw
      @total_records = 1
      @records_filtered = 1
  end

  def show #index (old index)

    @q = Quote.find(params[:id])
    @quotes = @q.quote_benefit_groups#Quote.where("broker_role_id" => current_user.person.broker_role.id, "aasm_state" => "draft")
    @all_quotes = @q.quote_benefit_groups
    #TODO fix this antipattern, make mongo field default, look at hbx_slug pattern?
    #@all_quotes.each{|q|q.update_attributes(claim_code: q.employer_claim_code) if q.claim_code==''}
    active_year = Date.today.year
    @coverage_kind = "health"
    @health_plans = $quote_shop_health_plans

    @dental_plans = $quote_shop_dental_plans
    @dental_plans_count = @dental_plans.count

    @health_selectors = $quote_shop_health_selectors
    @health_plan_quote_criteria  = $quote_shop_health_plan_features.to_json

    @dental_selectors = $quote_shop_dental_selectors
    dental_plan_quote_criteria  = $quote_shop_dental_plan_features.to_json
    @bp_hash = {'employee':50, 'spouse': 0, 'domestic_partner': 0, 'child_under_26': 0, 'child_26_and_over': 0}
    @q =  Quote.find(params[:quote]).quote_relationship_benefits.first if !params[:quote].nil?
    @quote_on_page = @q.quote_benefit_groups.first || @all_quotes.first
    @quote_criteria = []
    unless @quote_on_page.nil?
      @quote_on_page.quote_relationship_benefits.each{|bp| @bp_hash[bp.relationship] = bp.premium_pct}
      roster_premiums = @quote_on_page.roster_cost_all_plans
      @roster_premiums_json = roster_premiums.to_json
      dental_roster_premiums =  @quote_on_page.roster_cost_all_plans('dental')
      @dental_roster_premiums = dental_roster_premiums.to_json
      #TODOJF
      @quote_criteria = @quote_on_page.criteria_for_ui
    end
    @benefit_pcts_json = @bp_hash.to_json
    #temp stuff until publish is fixed
    @quote = @quote_on_page
    @plan = @quote && @quote.plan
    if @plan
      @plans_offered = @quote.cost_for_plans([@plan], @plan).sort_by { |k| [k["employer_cost"], k["employee_cost"]] }
    else
      @plans_offered =[]
    end
    @benefit_pcts_json = @bp_hash.to_json
  end

  def health_cost_comparison
      @q =  Quote.find(params[:quote])
      @quote_results = Hash.new
      @quote_results_summary = Hash.new
      @health_plans = $quote_shop_health_plans
      unless @q.nil?
        roster_premiums = @q.roster_cost_all_plans
        @roster_elected_plan_bounds = PlanCostDecoratorQuote.elected_plans_cost_bounds(@health_plans,
          @q.quote_relationship_benefits, roster_premiums)
        params['plans'].each do |plan_id|
          p = $quote_shop_health_plans.detect{|plan| plan.id.to_s == plan_id}

          detailCost = Array.new
          @q.quote_households.each do |hh|
            pcd = PlanCostDecorator.new(p, hh, @q, p)
            detailCost << pcd.get_family_details_hash.sort_by { |m| [m[:family_id], -m[:age], -m[:employee_contribution]] }
          end

          employer_cost = @q.roster_employer_contribution(p,p)
          @quote_results[p.name] = {:detail => detailCost,
            :total_employee_cost => @q.roster_employee_cost(p,p),
            :total_employer_cost => employer_cost,
            plan_id: plan_id,
            buy_up: PlanCostDecoratorQuote.buy_up(employer_cost, p.metal_level, @roster_elected_plan_bounds)
          }
        end
        @quote_results = @quote_results.sort_by { |k, v| v[:total_employer_cost] }.to_h
      end
    render partial: 'health_cost_comparison'
  end

  def dental_cost_comparison
    render partial: 'dental_cost_comparison', layout: false
  end

  def plan_comparison
    standard_component_ids = get_standard_component_ids
    @qhps = Products::QhpCostShareVariance.find_qhp_cost_share_variances(standard_component_ids, @active_year, "Health")
    @sort_by = params[:sort_by]
    order = @sort_by == session[:sort_by_copay] ? -1 : 1
    session[:sort_by_copay] = order == 1 ? @sort_by : ''
    if @sort_by && @sort_by.length > 0
      @sort_by = @sort_by.strip
      sort_array = []
      @qhps.each do |qhp|
        sort_array.push( [qhp, get_visit_cost(qhp,@sort_by)]  )
      end
      sort_array.sort!{|a,b| a[1]*order <=> b[1]*order}
      @qhps = sort_array.map{|item| item[0]}
    end

    if params[:export_to_pdf].present?
      if (plan_keys = params[:plan_keys]).present?
        @standard_plans = []
        plan_keys.split(',').each { |plan_key| @standard_plans << Plan.find(plan_key).hios_id }
        @qhps = []
        @standard_plans.each { |plan_id| @qhps << Products::QhpCostShareVariance
                                                              .find_qhp_cost_share_variances([plan_id], active_year, "Health") }
        @qhps.flatten!
      end
      render pdf: 'plan_comparison_export',
            template: 'broker_agencies/quotes/_plan_comparison_export.html.erb',
            disposition: 'attachment',
            locals: { qhps: @qhps }
    else
      render partial: 'plan_comparision', layout: false, locals: {qhps: @qhps}
    end
  end

  #def show
  #  @quote = Quote.find(params[:id])
  #end

  def download_employee_roster
    @quote = Quote.find(params[:id])
    @employee_roster = @quote.quote_households.map(&:quote_members).flatten
    send_data(csv_for(@employee_roster), :type => 'text/csv; charset=iso-8859-1; header=present',
    :disposition => "attachment; filename=Employee_Roster.csv")
  end

  def destroy
    if @quote.destroy
      respond_to do |format|
        format.js { render :text => "deleted Successfully" , :status => 200 }
      end
    end
  end

  def update_benefits
    q = Quote.find(params['id'])
    benefits = params['benefits']
    q.quote_relationship_benefits.each {|b| b.update_attributes!(premium_pct: benefits[b.relationship]) }
    render json: {}
  end

  def get_quote_info
    bp_hash = {}
    q =  Quote.find(params[:quote])
    summary = {name: q.quote_name,
     status: q.aasm_state.capitalize,
     plan_name: q.plan && q.plan.name || 'None',
     dental_plan_name: q.dental_plan && q.dental_plan.name || 'None',
   }
    q.quote_relationship_benefits.each{|bp| bp_hash[bp.relationship] = bp.premium_pct}
    render json: {'relationship_benefits' => bp_hash, 'roster_premiums' => q.roster_cost_all_plans, 'criteria' => JSON.parse(q.criteria_for_ui), summary: summary}
  end

  def publish
    @quote = Quote.find(params[:quote_id])
    if params[:plan_id]
      @plan = Plan.find(params[:plan_id][8,100])
      @elected_plan_choice = ['na', 'Single Plan', 'Single Carrier', 'Metal Level'][params[:elected].to_i]
      @quote.plan = @plan
      @quote.plan_option_kind = @elected_plan_choice
      @roster_elected_plan_bounds = PlanCostDecoratorQuote.elected_plans_cost_bounds($quote_shop_health_plans,
        @quote.quote_relationship_benefits, @quote.roster_cost_all_plans)
      case @elected_plan_choice
        when 'Single Carrier'
          @offering_param  = @plan.name
          @quote.published_lowest_cost_plan = @roster_elected_plan_bounds[:carrier_low_plan][@plan.carrier_profile.abbrev]
          @quote.published_highest_cost_plan = @roster_elected_plan_bounds[:carrier_high_plan][@plan.carrier_profile.abbrev]
        when 'Metal Level'
          @offering_param  = @plan.metal_level.capitalize
          @quote.published_lowest_cost_plan = @roster_elected_plan_bounds[:metal_low_plan][@plan.metal_level]
          @quote.published_highest_cost_plan = @roster_elected_plan_bounds[:metal_high_plan][@plan.metal_level]
        else
          @offering_param = ""
          @quote.published_lowest_cost_plan = @plan
          @quote.published_highest_cost_plan = @plan
      end
      @quote.save
    else
      @plan = @quote.plan
      @elected_plan_choice = @quote.plan_option_kind
    end

    if @plan
      @plans_offered = @quote.cost_for_plans([@plan], @plan).sort_by { |k| [k["employer_cost"], k["employee_cost"]] }
    else
      @plans_offered = []
    end
    respond_to do |format|
      format.html {render partial: 'publish'}
      format.pdf do
          render :pdf => "publised_quote",
                 :template => "/broker_agencies/quotes/_publish.pdf.erb"
      end
    end
  end

  def criteria
    if params[:quote_id]
      q = Quote.find(params[:quote_id])
      criteria_for_ui = params[:criteria_for_ui]
      q.update_attributes!(criteria_for_ui: criteria_for_ui ) if criteria_for_ui
      render json: JSON.parse(q.criteria_for_ui)
    else
      render json: []
    end
  end

  def export_to_pdf
    @pdf_url = "/broker_agencies/quotes/download_pdf?"
  end

  def download_pdf
    @standard_plans = []
    params[:plan_keys].each { |plan_key| @standard_plans << Plan.find(plan_key).hios_id }
    @qhps = []
    @standard_plans.each { |plan_id| @qhps << Products::QhpCostShareVariance
                                                            .find_qhp_cost_share_variances([plan_id], Date.today.year, "Health") }
    @qhps.flatten!
    render pdf: 'plan_comparison_export',
           template: 'broker_agencies/quotes/_plan_comparison_export.html.erb',
           disposition: 'attachment',
           locals: { qhps: @qhps }
  end

  def dental_plans_data
    set_dental_plans
  end


private

  def employee_relationship_map
    @employee_relationship_map = {"employee" => "Employee", "spouse" => "Spouse", "domestic_partner" => "Domestic Partner", "child_under_26" => "Child"}
  end

 def get_standard_component_ids
  Plan.where(:_id => { '$in': params[:plans] } ).map(&:hios_id)
 end

 def quote_params
    params.require(:quote).permit(
                    :quote_name,
                    :start_on,
                    :broker_role_id,
                    :quote_households_attributes => [ :id, :family_id , :quote_benefit_group_id,
                                       :quote_members_attributes => [ :id, :first_name, :last_name ,:dob,
                                                                      :employee_relationship,:_delete ] ] )
 end

  def employee_roster_group_by_family_id
    params[:employee_roster].inject({}) do  |new_hash,e|
      new_hash[e[1][:family_id]].nil? ? new_hash[e[1][:family_id]] = [e[1]]  : new_hash[e[1][:family_id]] << e[1]
      new_hash
    end
  end

  def find_quote
    @quote = Quote.find(params[:id])
  end

  # def parse_employee_roster_file
  #   begin
  #     CSV.parse(params[:employee_roster_file].read) if params[:employee_roster_file].present?
  #   rescue Exception => e
  #     flash[:error] = "Unable to parse the csv file"
  #     #redirect_to :action => "new" and return
  #   end
  # end

  def csv_for(employee_roster)
    (output = "").tap do
      CSV.generate(output) do |csv|
        csv << ["FamilyID", "Relationship", "DOB"]
        employee_roster.each do |employee|
          csv << [  employee.family_id,
                    employee.employee_relationship,
                    employee.dob
                  ]
        end
      end
    end
  end

  def dollar_value copay
    return 10000 if copay == 'Not Applicable'
    cost = 0
    cost += 1000 if copay.match(/after deductible/)
    return cost if copay.match(/No charge/)
    dollars = copay.match(/(\d+)/)
    cost += (dollars && dollars[1]).to_i || 0
  end

  def get_visit_cost qhp_cost_share_variance, visit_type
    service_visit = qhp_cost_share_variance.qhp_service_visits.detect{|v| visit_type == v.visit_type }
    cost = dollar_value service_visit.copay_in_network_tier_1
  end

  def set_qhp_variables
    @active_year = Date.today.year
    @coverage_kind = "health"
    @visit_types = @coverage_kind == "health" ? Products::Qhp::VISIT_TYPES : Products::Qhp::DENTAL_VISIT_TYPES
  end

  def set_dental_plans
    @dental_plans = Plan.shop_dental_by_active_year(2016)
    @dental_plans_count = Plan.shop_dental_by_active_year(2016).count
    @dental_plans = @dental_plans.by_carrier_profile(params[:carrier_id]) if params[:carrier_id].present? && params[:carrier_id] != 'any'
    @dental_plans = @dental_plans.by_dental_level(params[:dental_level]) if params[:dental_level].present? && params[:dental_level] != 'any'
    @dental_plans = @dental_plans.by_plan_type(params[:plan_type]) if params[:plan_type].present? && params[:plan_type] != 'any'
    @dental_plans = @dental_plans.by_dc_network(params[:dc_network]) if params[:dc_network].present? && params[:dc_network] != 'any'
    @dental_plans = @dental_plans.by_nationwide(params[:nationwide]) if params[:nationwide].present? && params[:nationwide] != 'any'
  end
end
