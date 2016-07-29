module AuditTrail

  # Post Journal Entries

  # Configure history tracker based on parent class
  ## journal class
  ## tracked events
  ## included attributes
  ## other options
  # Determine event type and fire

  def initialize(args)
    super(args)
    klass.configure_tracker
  end

  def klass
    self.class.name.classify.constantize
  end

  # Fire events
  def fire_event
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def configure_tracker
      track_history(audit_options)
    end

    # Build the Mongoid::History options
    # Track all fields and relations
    # Track all action types
    def audit_options
      {
        on: self.fields.keys + self.relations.keys,
        except: [:created_at, :updated_at], 
        track_create: true, track_update: true, track_destroy: true, 
        version_field: :version
        # changes_method: :my_changes
      }
    end
  end

end
