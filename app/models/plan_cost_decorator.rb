class PlanCostDecorator < SimpleDelegator
  attr_reader :member_provider, :benefit_group, :reference_plan

  include ShopPolicyCalculations

  def initialize(plan, member_provider, benefit_group, reference_plan, max_cont_cache = {})
    super(plan)
    @member_provider = member_provider
    @benefit_group = benefit_group
    @reference_plan = reference_plan
    @max_contribution_cache = max_cont_cache
  end

  def plan_year_start_on
    #FIXME only for temp ivl
    #binding.pry
    if @benefit_group.present? && @benefit_group.class != QuoteBenefitGroup
      benefit_group.plan_year.start_on
    elsif @benefit_group.class == QuoteBenefitGroup
      benefit_group.quote.start_on
    else
      TimeKeeper.date_of_record.beginning_of_year + 5.months
    end
  end

  def child_index(member)
    @children = members.select(){|member| age_of(member) < 21} unless defined?(@children)
    @children.index(member)
  end

  def self.benefit_relationship(person_relationship)
    {
      "head of household" => nil,
      "spouse" => "spouse",
      "ex-spouse" => "spouse",
      "cousin" => nil,
      "ward" => "child_under_26",
      "trustee" => "child_under_26",
      "annuitant" => nil,
      "other relationship" => nil,
      "other relative" => nil,
      "self" => "employee",
      "parent" => nil,
      "grandparent" => nil,
      "aunt_or_uncle" => nil,
      "nephew_or_niece" => nil,
      "father_or_mother_in_law" => nil,
      "daughter_or_son_in_law" => nil,
      "brother_or_sister_in_law" => nil,
      "adopted_child" => "child_under_26",
      "stepparent" => nil,
      "foster_child" => "child_under_26",
      "sibling" => nil,
      "stepchild" => "child_under_26",
      "sponsored_dependent" => "child_under_26",
      "dependent_of_a_minor_dependent" => nil,
      "guardian" => nil,
      "court_appointed_guardian" => nil,
      "collateral_dependent" => "child_under_26",
      "life_partner" => "domestic_partner",
      "child" => "child_under_26",
      "grandchild" => nil,
      "unrelated" => nil,
      "great_grandparent" => nil,
      "great_grandchild" => nil,
    }[person_relationship]
  end

  def relationship_benefit_for(member)
    relationship = relationship_for(member)
    @reference_plan.coverage_kind == 'dental' ? benefit_group.dental_relationship_benefit_for(relationship) : benefit_group.relationship_benefit_for(relationship)
  end

  def employer_contribution_percent(member)
    relationship_benefit = relationship_benefit_for(member)
    if relationship_benefit && relationship_benefit.offered?
      relationship_benefit.premium_pct
    else
      0.00
    end
  end

  def reference_premium_for(member)
    (reference_plan.premium_for(plan_year_start_on, age_of(member)) * large_family_factor(member)).round(2)
  rescue
    0.00
  end

  def premium_for(member)
    relationship_benefit = relationship_benefit_for(member)
    if relationship_benefit && relationship_benefit.offered?
      (Caches::PlanDetails.lookup_rate(__getobj__.id, plan_year_start_on, age_of(member)) * large_family_factor(member)).round(2)
    else
      0.00
    end
  end

  def max_employer_contribution(member)
    return @max_contribution_cache.fetch(member._id) if @max_contribution_cache.has_key?(member._id)
    @max_contribution_cache[member._id] = ((large_family_factor(member) * (reference_premium_for(member) * employer_contribution_percent(member))) / 100.00).round(2)
  end

  def employer_contribution_for(member)
    ([max_employer_contribution(member), premium_for(member)].min * large_family_factor(member)).round(2)
  end

  def employee_cost_for(member)
    (if @benefit_group.present?
      premium_for(member) - employer_contribution_for(member)
    else
      __getobj__.premium_for(plan_year_start_on, age_of(member))
    end * large_family_factor(member)).round(2)
  end

  def total_employer_contribution
    (members.reduce(0.00) do |sum, member|
      (sum + employer_contribution_for(member)).round(2)
    end).round(2)
  end

  def total_employee_cost
    (members.reduce(0.00) do |sum, member|
      (sum + employee_cost_for(member)).round(2)
    end).round(2)
  end

  def get_family_details
    members.collect{ |m| [@reference_plan.name, m.first_name, m.employee_relationship, m.age_on(TimeKeeper.date_of_record), m.quote_households.id, employee_cost_for(m), employer_contribution_for(m)]}
  end

  def get_family_details_hash
    members.map{ |m|
      {
        :plan => @reference_plan.name,
        :first_name => m.first_name,
        :employee_relationship => m.employee_relationship,
        :age => m.age_on(TimeKeeper.date_of_record),
        :family_id => m.quote_households.id,
        :employee_cost => employee_cost_for(m),
        :employer_contribution_percent => employer_contribution_percent(m),
        :employee_contribution => employer_contribution_for(m),
        :total_premium => employee_cost_for(m).round(2) + employer_contribution_for(m).round(2)}}
  end


end
