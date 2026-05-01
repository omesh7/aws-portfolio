// API URL will be injected during deployment
const API_URL = window.LAMBDA_API_URL || "LAMBDA_URL_PLACEHOLDER";

const cityInput = document.getElementById("cityInput");
const searchBtn = document.getElementById("searchBtn");
const weatherCard = document.getElementById("weatherCard");
const errorMessage = document.getElementById("errorMessage");

const cityName = document.getElementById("cityName");
const temp = document.getElementById("temp");
const description = document.getElementById("description");
const feelsLike = document.getElementById("feelsLike");
const humidity = document.getElementById("humidity");
const windSpeed = document.getElementById("windSpeed");

searchBtn.addEventListener("click", getWeather);
cityInput.addEventListener("keypress", (e) => {
  if (e.key === "Enter") getWeather();
});

async function getWeather() {
  const city = cityInput.value.trim();

  if (!city) {
    showError("Please enter a city name");
    return;
  }

  try {
    searchBtn.textContent = "Loading...";
    searchBtn.disabled = true;

    const url = `${API_URL}?city=${encodeURIComponent(city)}`;
    console.log("Fetching:", url);

    const response = await fetch(url);
    console.log("Response status:", response.status);

    const data = await response.json();
    console.log("Response data:", data);

    if (!response.ok) {
      // Handle specific API error messages
      if (data.message) {
        throw new Error(data.message);
      } else if (response.status === 404) {
        throw new Error("City not found. Please check the spelling.");
      } else if (response.status === 401) {
        throw new Error("Invalid API key. Please check your configuration.");
      } else {
        throw new Error(`API Error: ${response.status}`);
      }
    }

    displayWeather(data);
  } catch (error) {
    console.error("Weather fetch error:", error);
    showError(error.message);
  } finally {
    searchBtn.textContent = "Get Weather";
    searchBtn.disabled = false;
  }
}

function displayWeather(data) {
  hideError();

  cityName.textContent = `${data.name}, ${data.sys.country}`;
  temp.textContent = Math.round(data.main.temp);
  description.textContent = data.weather[0].description;
  feelsLike.textContent = `${Math.round(data.main.feels_like)}°C`;
  humidity.textContent = `${data.main.humidity}%`;
  windSpeed.textContent = `${data.wind.speed} m/s`;

  weatherCard.classList.remove("hidden");
}

function showError(message) {
  errorMessage.textContent = message;
  errorMessage.classList.remove("hidden");
  weatherCard.classList.add("hidden");
}

function hideError() {
  errorMessage.classList.add("hidden");
}

// Detect which cloud platform is serving the app
function detectCloudPlatform() {
  const hostname = window.location.hostname;

  if (
    hostname.includes("amazonaws.com") ||
    hostname.includes("cloudfront.net")
  ) {
    document.querySelector(".status-dot.aws").style.background = "#00b894";
    document.querySelector(".status-dot.azure").style.background = "#ddd";
  } else if (
    hostname.includes("azurewebsites.net") ||
    hostname.includes("blob.core.windows.net")
  ) {
    document.querySelector(".status-dot.azure").style.background = "#00b894";
    document.querySelector(".status-dot.aws").style.background = "#ddd";
  }
}

// Initialize
detectCloudPlatform();

console.log("Weather app initialized. API URL:", API_URL);
