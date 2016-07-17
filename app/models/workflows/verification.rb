class Workflows::Verification
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  ASSIGNED    = %w(assigned processing reviewing customer_response_pending)
  UNASSIGNED  = %w(submitted)
  OPEN        = ASSIGNED + UNASSIGNED
  CLOSED      = %w(approved denied verified expired)

  embedded_in :verifiable, polymorphic: true
  embeds_many :workflow_state_transitions, as: :transitional

  scope :assigned,    ->{ any_in(aasm_state: ASSIGNED) }
  scope :unassigned,  ->{ any_in(aasm_state: UNASSIGNED) }
  scope :open,        ->{ any_in(aasm_state: OPEN) }
  scope :closed,      ->{ any_in(aasm_state: CLOSED) }

  field :assigned_to, type: String
  field :submitted_by, type: BSON::ObjectId
  field :submitted_at, type: Time


  aasm do
    state :new, initial: true
    state :submitted    # case posted for hbx verification
    state :assigned     # assigned to case worker queue
    state :processing   # case worker 
    state :reviewing    # under peer or supervisory review
    state :customer_response_pending  # returned to customer for supplementary info

    state :approved
    state :denied
    state :verified
    state :expired

    event :submit, :after => :record_transition do
      transitions from: :new, to: :submitted, :after => :set_submitted_at_time
    end

    event :reopen, :after => :record_transition do
      transitions from: [:approved, :denied, :verified, :expired], to: :submitted
    end

    event :assign, :after => :record_transition do
      transitions from: [:submitted, :assigned], to: :assigned
    end

    event :review, :after => :record_transition do
      transitions from: [:submitted, :assigned, :feedback], to: :reviewing
    end

    event :refer_to_customer, :after => :record_transition do
      transitions from: :reviewing, to: :customer_response_pending
    end

    event :refer_to_hbx, :after => :record_transition do
      transitions from: :customer_response_pending, to: :reviewing
    end

    event :approve, :after => :record_transition do
      transitions from: :reviewing, to: :approved
    end

    event :deny, :after => :record_transition do
      transitions from: :reviewing, to: :denied
    end

    event :expire, :after => :record_transition do
      transitions from: :customer_response_pending, to: :expired
    end

    event :verify, :after => :record_transition do
      transitions from: :reviewing, to: :verified
    end
  end

private
  def set_submitted_at_time
    self.submitted_at = TimeKeeper.datetime_of_record
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end


end