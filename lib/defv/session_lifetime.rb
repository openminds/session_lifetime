module Defv
  module SessionLifetime
    module ClassMethods
      def expires_session options = {}
        cattr_accessor :_session_expiry
        cattr_accessor :_redirect_to
        
        self._session_expiry = options[:time] || 1.hour
        self._redirect_to = options[:redirect_to] || '/'
        
        self.before_filter :check_session_lifetime
      end
    end
    
    module InstanceMethods
        protected
        
        def check_session_lifetime
          if session[:updated_at] && session[:updated_at] + self._session_expiry < Time.now
            reset_session
            redirect_to self._redirect_to
            self.send(:on_expiry) if self.methods.include?('on_expiry')
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