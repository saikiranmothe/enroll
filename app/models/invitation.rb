class Invitation
  include Mongoid::Document

  INVITE_TYPES = {
    "census_employee" => "employee_role",
    "broker_role" => "broker_role",
    "employer_profile" => "employer_profile"
  }
  ROLES = INVITE_TYPES.values
  SOURCE_KINDS = INVITE_TYPES.keys

  field :role, type: String
  field :source_id, type: BSON::ObjectId
  field :source_kind, type: String

  validates_presence_of :role, :allow_blank => false
  validates_presence_of :source_id, :allow_blank => false
  validates :source_kind, :inclusion => { in: SOURCE_KINDS }, :allow_blank => false

  validate :allowed_invite_types

  def allowed_invite_types
    result_type = INVITE_TYPES[self.source_kind]
    check_role = result_type.blank? ? nil : result_type.downcase
    return if (self.source_kind.blank? || self.role.blank?)
    if result_type != self.role.downcase
      errors.add(:base, "a combination of source #{self.source_kind} and role #{self.role} is invalid")
    end
  end
end
