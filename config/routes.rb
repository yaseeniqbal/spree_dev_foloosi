Spree::Core::Engine.add_routes do
  # Add your extension routes here
  post '/foloosi', 			 :to =>    "foloosi#express", :as => :foloosi_v2
	get '/foloosi_r_auth', :to =>    "foloosi#receiver_authorized_transactions", :as => :foloosi_v2_authorized
	get '/foloosi_r_can',  :to =>    "foloosi#receiver_decl_transactions", :as => :foloosi_v2_declined
	get '/foloosi_r_decl', :to => 	 "foloosi#receiver_cancelled_transactions", :as => :foloosi_v2_cancelled
	get '/iniatization_foloosi_response', :to =>    "foloosi#iniatization_response", :as => :iniatization_foloosi_response


end
