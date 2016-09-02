require "rails_helper"

RSpec.describe "broker_agencies/profiles/edit.html.erb" do
  let(:organization) { FactoryGirl.create(:organization) }
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }

  before :each do
    org_form = Forms::BrokerAgencyProfile.find(broker_agency_profile.id)
    assign :organization, org_form
    assign :broker_agency_profile, broker_agency_profile
    assign :id, broker_agency_profile.id
    render template: "broker_agencies/profiles/edit.html.erb"
  end

  it "should have title" do
    expect(rendered).to have_selector('h4', text: 'Personal Information')
    expect(rendered).to have_selector('h4', text: 'Broker Agency Information')
  end
  it "should block the market kind dropdown refs #9818" do
    expect(rendered).to have_selector('.broker-agency-info.read_only_dropdown')
  end
  it "should have four read only fields refs #9818"  do
    expect(rendered).to have_selector("[readonly='readonly']", count: 4)
  end
end
