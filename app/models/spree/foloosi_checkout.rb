module Spree
  class FoloosiCheckout < ActiveRecord::Base

  	def error_msg
  		# status = foloosi_errors.last.dig("order","transaction","status")
			#
  		# msg
			''
  	end
  end
end