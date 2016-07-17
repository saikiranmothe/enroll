# Set default history tracker class name

Mongoid::History.tracker_class_name = :"journals/standard_transaction"
Mongoid::History.current_user_method = :current_user