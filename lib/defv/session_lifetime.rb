module Defv
  module SessionLifetime
    module ClassMethods
      # Set the session expiring
      #
      # Options:
      #   * :time - After how much time of inactivity should the session be invalidated. Default is 1 hour
      #   * :redirect_to - Where should we redirect the user to once their session has expired
      #   * :redirect_with - Use a function to redirect the user. Overrides redirect_to.
      #   * :on_expiry - Takes a Proc or a lamba which gives you a callback after the session invalidation. This is useful for setting a flash message or something in the database.
      def expires_session options = {}
        options.reverse_merge!({
          :time => 1.hour,
          :redirect_to => '/'
        })
        
        write_inheritable_attribute "@session_expiry_options", options
    
        self.before_filter :check_session_lifetime
      end
    end
    
    module InstanceMethods
        protected
        
        def check_session_lifetime
          # Get the attribute set by expires_session
          options = self.class.read_inheritable_attribute('@session_expiry_options')

          # Session is expired
          if session[:updated_at] && session[:updated_at] + options[:time] < Time.now
            reset_session
            
            # Redirect (either with redirect_with or redirect_to)
            if options[:redirect_with]
              self.send(options[:redirect_with])
            else
              redirect_to options[:redirect_to]
            end
            
            # Call the on_expiry proc if one is given
            if options[:on_expiry]
              if options[:on_expiry].arity == 1
                options[:on_expiry].call(self)
              else
                instance_eval(&options[:on_expiry])
              end
            elsif self.methods.include?('on_expiry') # Legacy, call the on_expiry method if one is defined
              self.send(:on_expiry) 
            end
          else
            session[:updated_at] = Time.now
          end
        end
    end
    
    def self.included(receiver)
      receiver.extend ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end