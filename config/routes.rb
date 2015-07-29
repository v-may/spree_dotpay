Spree::Core::Engine.routes.draw do
  namespace :offsite_payment do
    post '/dotpay', to: "dotpay#purchase"
    get '/dotpay', to: "dotpay#purchase"
    post '/dotpay/notify', to: "dotpay#notify", as: :notify_dotpay
    post '/dotpay/return', to: "dotpay#done", as: :return_dotpay
  end
end
