// app/assets/javascripts/geotracker.js

var GeoTracker = {
    map: null,
    markers: [],
  
    init: function(containerId, locations) {
      this.map = L.map(containerId);
      
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
      }).addTo(this.map);
  
      if (locations && locations.length > 0) {
        this.loadLocations(locations);
      }
    },
  
    loadLocations: function(locations) {
      var bounds = L.latLngBounds();
      
      locations.forEach(function(loc) {
        var marker = L.marker([loc.lat, loc.lng], {
          title: loc.title
        });
        
        if (loc.popup) {
          marker.bindPopup(loc.popup);
        }
        
        marker.addTo(this.map);
        this.markers.push(marker);
        bounds.extend([loc.lat, loc.lng]);
      }.bind(this));
  
      this.map.fitBounds(bounds);
    },
  
    clearLocations: function() {
      this.markers.forEach(function(marker) {
        this.map.removeLayer(marker);
      }.bind(this));
      this.markers = [];
    },
  
    getCurrentPosition: function(callback) {
      if ("geolocation" in navigator) {
        navigator.geolocation.getCurrentPosition(function(position) {
          callback({
            lat: position.coords.latitude,
            lng: position.coords.longitude,
            accuracy: position.coords.accuracy
          });
        }, function(error) {
          console.error("Error getting location:", error);
        });
      } else {
        console.error("Geolocation is not supported by this browser.");
      }
    }
  };
  
  // Inicialización cuando el documento está listo
  document.addEventListener('DOMContentLoaded', function() {
    var mapContainer = document.getElementById('locations-map');
    if (mapContainer) {
      var locations = JSON.parse(mapContainer.dataset.locations || '[]');
      GeoTracker.init('locations-map', locations);
    }
  });