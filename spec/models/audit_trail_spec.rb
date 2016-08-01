require 'rails_helper'

RSpec.describe AuditTrail, type: :model do

  context "General configuration" do
    let(:default_tracker_class_name)  { :action_journal }

    it "a default collection to store tracked history should be referenced" do
      expect(Mongoid::History.tracker_class_name).to eq default_tracker_class_name
    end
  end

  context "A history tracked instance is created and no audit history tracking options are specified" do
    let(:modifier_field)    { :updated_by }
    let(:version_field)     { :version }
    let(:changes_method)    { :changes }
    let(:first_name)        { "john" }
    let(:last_name)         { "doe" }
    let(:parent_klass)      { "person".camelize.constantize }
    let(:parent_klass_key)  { parent_klass.name.underscore.downcase.to_sym }
    let!(:parent_instance)  { parent_klass.create(first_name: first_name, last_name: last_name) }

    describe "the class should initialize with default history tracking options" do
      it { expect(Mongoid::History.trackable_class_options.keys).to include(parent_klass_key) }
      it { expect(Mongoid::History.trackable_class_options[parent_klass_key][:track_create]).to be_truthy }
      it { expect(Mongoid::History.trackable_class_options[parent_klass_key][:track_update]).to be_truthy }
      it { expect(Mongoid::History.trackable_class_options[parent_klass_key][:track_destroy]).to be_truthy }
      it { expect(Mongoid::History.trackable_class_options[parent_klass_key][:modifier_field]).to eq modifier_field }
      it { expect(Mongoid::History.trackable_class_options[parent_klass_key][:changes_method]).to eq changes_method }
    end

    describe "and the instance should have one change record for the create action" do
      it { expect(parent_instance.history_tracks.count).to eq 1 } 
      it { expect(parent_instance.history_tracks.first.action).to eq "create" } 
      it { expect(parent_instance.history_tracks.first.version).to eq 1 } 
      it { expect(parent_instance.history_tracks.first.original).to eq Hash.new } 
      it { expect(parent_instance.history_tracks.first.modified["first_name"]).to eq first_name } 
      it { expect(parent_instance.history_tracks.first.modified["last_name"]).to eq last_name } 
    end

    context "and an embeds_many child instance is created" do
      let(:child_klass_name)  { "emails" }
      let(:child_klass)       { child_klass_name.singularize.camelize.constantize }
      let(:child_klass_key)   { child_klass_name.to_sym }
      let(:email_kind)        { "work" }
      let(:email_address)     { "#{first_name}.#{last_name}@example.com" }
      let!(:child_instance)   { parent_instance.emails.create(kind: email_kind, address: email_address) }

      describe "the child instance should increment the parent instance count and store a change record" do
        it { expect(parent_instance.history_tracks.count).to eq 2 }
        it { expect(child_instance.history_tracks.last.action).to eq "create" } 
        it { expect(child_instance.history_tracks.last.version).to eq 1 } 
        it { expect(child_instance.history_tracks.last.trackable_parent_class.to_s).to eq parent_klass.name }
        it { expect(child_instance.history_tracks.last.trackable_root).to eq parent_instance }
        it { expect(child_instance.history_tracks.last.original).to eq Hash.new }
        it { expect(child_instance.history_tracks.last.modified["kind"]).to eq email_kind }
        it { expect(child_instance.history_tracks.last.modified["address"]).to eq email_address }
        it "should assign association_chain" do
          expected = [
              { "name" => parent_klass.name, "id" => parent_instance.id },
              { "name" => child_klass.name.downcase.pluralize, "id" => child_instance.id }
            ]
            expect(child_instance.history_tracks.last.association_chain).to eq expected
        end
        it { expect(child_instance.history_tracks.last.association_chain.first[:name]).to eq "Person" }
        it { expect(child_instance.history_tracks.last.association_chain.last[:name]).to eq "emails" }
      end
    end

    context "and no history tracking options are provided" do
    end

  end
end
