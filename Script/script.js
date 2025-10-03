function openMap() {
  document.getElementById("mapContainer").style.display = "block";
  initMap();
}

function closeMap() {
  document.getElementById("mapContainer").style.display = "none";
}

function predictWeather() {
  let place = document.getElementById("place").value;
  let date = document.getElementById("date").value;

  if (!place || !date) {
    document.getElementById("predictionBox").innerText = "⚠️ Please enter both location and date!";
    return;
  }

  let weathers = ["Sunny", "Cloudy", "Windy", "Stormy", "Rainy"];
  let randomWeather = weathers[Math.floor(Math.random() * weathers.length)];

  document.getElementById("predictionBox").innerHTML = 
    `<div>Weather in ${place} on ${date}:</div>
     <div class="weather-result">${randomWeather}</div>`;

  document.body.className = ""; 
  document.body.classList.add(randomWeather.toLowerCase());
}

var map;
var marker;

function initMap() {
  if (!map) {
    map = L.map('map').setView([30.0444, 31.2357], 6);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18,
    }).addTo(map);

    L.Control.geocoder({ defaultMarkGeocode: false })
      .on('markgeocode', function(e) {
        var latlng = e.geocode.center;

        if (marker) {
          map.removeLayer(marker);
        }
        marker = L.marker(latlng).addTo(map);
        map.setView(latlng, 10);

        document.getElementById("place").value = e.geocode.name;
        closeMap();
      })
      .addTo(map);

    map.on('click', function(e) {
      if (marker) {
        map.removeLayer(marker);
      }
      marker = L.marker(e.latlng).addTo(map);

      const lat = e.latlng.lat;
      const lon = e.latlng.lng;

      fetch(`https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json`)
        .then(response => response.json())
        .then(data => {
          const address = data.address;
          const road = address.road || "";
          const city = address.city || address.town || address.village || "";
          const state = address.state || "";

          let shortPlace = "";
          if (road) shortPlace += road + ", ";
          if (city) shortPlace += city;
          if (state && state !== city) shortPlace += ", " + state;

          if (!shortPlace) {
            shortPlace = `(${lat.toFixed(2)}, ${lon.toFixed(2)})`;
          }

          document.getElementById("place").value = shortPlace;
        })
        .catch(err => {
          console.error("Error getting location name:", err);
          document.getElementById("place").value = `(${lat.toFixed(2)}, ${lon.toFixed(2)})`;
        });

      closeMap();
    });
  }

  setTimeout(() => {
    map.invalidateSize();
  }, 300);
}
