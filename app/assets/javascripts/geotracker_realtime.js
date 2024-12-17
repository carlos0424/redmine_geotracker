// app/assets/javascripts/geotracker_realtime.js

var GeotrackerRealtime = {
    watchId: null,
    channel: null,
    updateInterval: 30000, // 30 segundos
    minimumDistance: 10,   // 10 metros
    lastPosition: null,
    
    init: function(projectId) {
      this.projectId = projectId;
      this.initializeChannel();
      this.initializeTracking();
      this.setupControls();
    },
    
    initializeChannel: function() {
      this.channel = App.cable.subscriptions.create(
        {
          channel: "GeotrackerLocationChannel",
          project_id: this.projectId
        },
        {
          connected: function() {
            console.log("Connected to location channel");
          },
          
          disconnected: function() {
            console.log("Disconnected from location channel");
          },
          
          received: function(data) {
            if (data.location) {
              GeoTracker.updateMarker(data.location);
            }
          }
        }
      );
    },
    
    initializeTracking: function() {
      if (!navigator.geolocation) {
        console.error("Geolocation is not supported");
        return;
      }
      
      var options = {
        enableHighAccuracy: true,
        timeout: 5000,
        maximumAge: 0
      };
      
      this.watchId = navigator.geolocation.watchPosition(
        this.handlePositionUpdate.bind(this),
        this.handlePositionError.bind(this),
        options
      );
    },
    
    handlePositionUpdate: function(position) {
      var newPosition = {
        lat: position.coords.latitude,
        lng: position.coords.longitude,
        accuracy: position.coords.accuracy
      };
      
      if (this.shouldUpdatePosition(newPosition)) {
        this.lastPosition = newPosition;
        this.sendUpdate(newPosition);
      }
    },
    
    shouldUpdatePosition: function(newPosition) {
      if (!this.lastPosition) return true;
      
      var distance = this.calculateDistance(
        this.lastPosition.lat, this.lastPosition.lng,
        newPosition.lat, newPosition.lng
      );
      
      return distance >= this.minimumDistance;
    },
    
    calculateDistance: function(lat1, lon1, lat2, lon2) {
      // Implementación de la fórmula haversine
      var R = 6371000; // Radio de la tierra en metros
      var φ1 = lat1 * Math.PI/180;
      var φ2 = lat2 * Math.PI/180;
      var Δφ = (lat2-lat1) * Math.PI/180;
      var Δλ = (lon2-lon1) * Math.PI/180;
  
      var a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2);
      var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  
      return R * c;
    },
    
    sendUpdate: function(position) {
      var data = {
        lat: position.lat,
        lng: position.lng,
        accuracy: position.accuracy,
        batteryLevel: this.getBatteryLevel(),
        connectionType: this.getConnectionType()
      };
      
      this.channel.perform('update_status', data);
    },
    
    getBatteryLevel: function() {
      return navigator.battery ? 
             navigator.battery.level * 100 : 
             null;
    },
    
    getConnectionType: function() {
      return navigator.connection ? 
             navigator.connection.effectiveType : 
             'unknown';
    },
    
    handlePositionError: function(error) {
      console.error("Error getting position:", error);
    },
    
    setupControls: function() {
      var trackingToggle = document.getElementById('tracking-toggle');
      if (trackingToggle) {
        trackingToggle.addEventListener('click', function() {
          if (this.watchId) {
            this.stopTracking();
          } else {
            this.startTracking();
          }
        }.bind(this));
      }
    },
    
    startTracking: function() {
      this.initializeTracking();
      document.getElementById('tracking-status').textContent = 'Tracking Active';
    },
    
    stopTracking: function() {
      if (this.watchId) {
        navigator.geolocation.clearWatch(this.watchId);
        this.watchId = null;
      }
      document.getElementById('tracking-status').textContent = 'Tracking Stopped';
    }
  };