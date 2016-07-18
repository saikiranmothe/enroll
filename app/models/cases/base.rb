class Cases::Base
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable


  # journal


  # Eligibility/Assistance
  ## QLEs
  ## Disabled child (prevent age-off)
  ## Financial assistance change
  ## Incarceration status
  ## Residency status

  # New Enrollment
  ## QLEs

  # Eligibility/Assistance (affects all existing/new enrollments)
  ## Change APTC
  ## Transfer subscriber/re-enrollment
  ### Medicare eligibility (QLE)
  ### Death
  ## Lawful presence verification expired
  ## Verified non-lawful presence
  ## Verified non-citizen

  # Existing enrollment
  ## Change effective date
  ## Add members to coverage
  ### loss of Medicaid eligibility (Loss of MEC QLE?)
  ## Drop members from coverage
  ### age-off
  ### newly Medicaid eligibile
  ### incarceration
  ## Dispute carrier cancel

  # Carrier signals
  ## Cancel enrollment
  ## Reinstate benefit
  ## Effectuation enrollment
  ## Address change
  ## Phone change
  ## Email change
  ## Member death

  ELIGIBILITY   = []
  ENROLLMENT    = []
  FAMILY        = []
  PERSON        = []
  EMPLOYEE_ROLE = []
  CONSUMER_ROLE = []

  HBX_EVIDENCE_KINDS    = %w(
                              open_enrollment_period_added
                              open_enrollment_period_dropped
                              open_enrollment_period_updated
                            )

  FAMILY_EVIDENCE_KINDS = %w(
                              created
                              archived
                              family_member_added
                              family_member_dropped

                              benefit_effective_date_disputed
                              financial_assistance_eligibility_disputed
                              aptc_disputed
                              carrier_cancel_disputed

                              benefit_enrollment_submitted
                              benefit_enrollment_acknowledged
                              benefit_enrollment_effectuated
                              benefit_enrollment_canceled
                              benefit_enrollment_terminated
                              benefit_effective_date_updated
                              income_updated
                              financial_assistance_eligibility_determined
                              financial_assistance_eligibility_updated
                              tax_filing_status_changed
                              aptc_updated

                              broker_added
                              broker_dropped

                              qualifying_life_event
                              incarceration_status_updated
                              disability_status_updated
                              residency_status_determined
                              residency_status_updated
                            )

  PERSON_EVIDENCE_KINDS = %w(
                              created
                              archived
                              merged

                              name_updated
                              dob_updated
                              ssn_updated
                              gender_updated
                              family_relationship_updated
                              address_updated
                              email_updated
                              phone_updated

                              identity_determined
                              hbx_role_added
                              hbx_role_dropped
                              language_preference_updated
                              ethnic_profile_udpated

                              citizen_status_determined
                              citizen_status_updated
                              lawful_presence_status_determined
                              lawful_presence_status_updated
                              lawful_presence_status_disputed
                            )

  EMPLOYEE_EVIDENCE_KINDS = %w(
                                benefit_enrollment_eligible
                                employment_terminated
                                benefit_waived
                                qualifying_life_event
                                cobra_enrollment_submitted
                                cobra_enrollment_canceled
                                cobra_enrollment_terminated
                              )

  ALL_EVIDENCE_KINDS      = %w(
                                eligibility
                                enrollment
                                person_information
                              )


  # embeds_one  :verification, class_name: "Workflows::Verification", as: :verifiable
  embeds_many :case_notes, as: :commentable
  embeds_many :consumer_notes, as: :commentable


  field :title, type: String
  field :role_kind, type: String  # model name
  field :evidence_kind, type: String
  field :effective_on, type: Date
  field :reason, type: String

  field :assigned_to,  type: BSON::ObjectId   # TODO: support multiple assignments
  field :approved_by, type: BSON::ObjectId

  field :related_case_ids, type: Array, default: []
  field :related_crm_ids,  type: Array, default: []

  field :attribute_list, type: Array, default: [] # used for tracking changes

  # accepts_nested_attributes_for :"workflows/verification", :case_notes, :consumer_notes



end