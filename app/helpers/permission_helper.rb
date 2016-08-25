# Use this in views.   Needed to make rspec work.
# allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: true))
# https://github.com/elabs/pundit/issues/339
# https://www.relishapp.com/rspec/rspec-rails/v/3-0/docs/view-specs/view-spec#passing-view-spec-that-stubs-a-helper-method
module PermissionHelper
  include Haml::Helpers

  def policy_helper pundit_object
    policy(pundit_object) 
  end

  def pundit_span pundit_object, pundit_method
    result = policy_helper(pundit_object).send(pundit_method) ? '<span class="no-op">' : ' <span class="blocking" >' 
    raw result
  end

  def pundit_class pundit_object, pundit_method
    result = policy_helper(pundit_object).send(pundit_method) ? ' no-op ' : '  blocking ' 
    raw result
  end

  def h_pundit_span(pundit_object, pundit_method)
    permission_cls = policy_helper(pundit_object).send(pundit_method) ? 'no-op' : 'blocking'
    haml_tag("span.#{permission_cls}") do
      yield
    end
  end

  def e_pundit_span(pundit_object, pundit_method, &blk)
    permission_cls = policy_helper(pundit_object).send(pundit_method) ? 'no-op' : 'blocking'
    content_tag("span", :class => permission_cls) do
      yield
    end
  end

end  
