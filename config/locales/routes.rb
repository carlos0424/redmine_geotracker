# config/routes.rb

RedmineApp::Application.routes.draw do
    resources :projects do
      resources :geotracker_locations do
        collection do
          get 'map'
          post 'batch_update'
        end
        member do
          post 'verify'
          post 'invalidate'
        end
      end
    end
  
    get 'geotracker_locations', to: 'geotracker_locations#index'
    get 'geotracker_locations/map_data', to: 'geotracker_locations#map_data'
    get 'geotracker_locations/download', to: 'geotracker_locations#download'
  end

  Rails.application.routes.draw do
    namespace :api do
      namespace :v1 do
        resources :projects, only: [] do
          resources :geotracker_locations do
            collection do
              post :batch_create
              get :stats
            end
          end
        end
        
        get 'geotracker/global_stats', to: 'geotracker_api#global_stats'
      end
    end
  end