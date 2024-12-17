// app/assets/javascripts/location_form.js

var GeoTracker = GeoTracker || {};

GeoTracker.initLocationPicker = function(containerId) {
  var map = L.map(containerId);
  var marker = null;
  
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors'
  }).addTo(map);

  map.on('click', function(e) {
    GeoTracker.setMarkerPosition(map, e.latlng.lat, e.latlng.lng);
  });

  // Centrar en una ubicación por defecto o en la ubicación actual
  map.setView([0, 0], 2);

  return map;
};

GeoTracker.setMarkerPosition = function(map, lat, lng) {
  // Actualizar los campos ocultos
  document.getElementById('location_lat').value = lat;
  document.getElementById('location_lng').value = lng;
  
  // Actualizar el display de coordenadas
  var display = document.querySelector('.coordinates-display');
  if (display) {
    display.textContent = lat.toFixed(6) + ', ' + lng.toFixed(6);
  }
  
  // Actualizar o crear el marcador
  if (this.currentMarker) {
    this.currentMarker.setLatLng([lat, lng]);
  } else {
    this.currentMarker = L.marker([lat, lng], {
      draggable: true
    }).addTo(map);
    
    this.currentMarker.on('dragend', function(e) {
      var position = e.target.getLatLng();
      GeoTracker.setMarkerPosition(map, position.lat, position.lng);
    });
  }
  
  // Centrar el mapa
  map.setView([lat, lng], 15);
};

// Función para obtener la ubicación actual
GeoTracker.getCurrentPosition = function(callback) {
  if ("geolocation" in navigator) {
    navigator.geolocation.getCurrentPosition(
      function(position) {
        callback({
          lat: position.coords.latitude,
          lng: position.coords.longitude,
          accuracy: position.coords.accuracy
        });
      },
      function(error) {
        console.error("Error getting location:", error);
      },
      {
        enableHighAccuracy: true,
        timeout: 5000,
        maximumAge: 0
      }
    );
  }
};