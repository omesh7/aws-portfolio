const API_KEY = 'YOUR_OPENWEATHER_API_KEY'; // Replace with your API key
const API_URL = 'https://api.openweathermap.org/data/2.5/weather';

const cityInput = document.getElementById('cityInput');
const searchBtn = document.getElementById('searchBtn');
const weatherCard = document.getElementById('weatherCard');
const errorMessage = document.getElementById('errorMessage');

const cityName = document.getElementById('cityName');
const temp = document.getElementById('temp');
const description = document.getElementById('description');
const feelsLike = document.getElementById('feelsLike');
const humidity = document.getElementById('humidity');
const windSpeed = document.getElementById('windSpeed');

searchBtn.addEventListener('click', getWeather);
cityInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') getWeather();
});

async function getWeather() {
    const city = cityInput.value.trim();
    
    if (!city) {
        showError('Please enter a city name');
        return;
    }
    
    if (!API_KEY || API_KEY === 'YOUR_OPENWEATHER_API_KEY') {
        showError('Please configure your OpenWeatherMap API key');
        return;
    }
    
    try {
        searchBtn.textContent = 'Loading...';
        searchBtn.disabled = true;
        
        const response = await fetch(`${API_URL}?q=${city}&appid=${API_KEY}&units=metric`);
        
        if (!response.ok) {
            throw new Error('City not found');
        }
        
        const data = await response.json();
        displayWeather(data);
        
    } catch (error) {
        showError(error.message);
    } finally {
        searchBtn.textContent = 'Get Weather';
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
    
    weatherCard.classList.remove('hidden');
}

function showError(message) {
    errorMessage.textContent = message;
    errorMessage.classList.remove('hidden');
    weatherCard.classList.add('hidden');
}

function hideError() {
    errorMessage.classList.add('hidden');
}

// Detect which cloud platform is serving the app
function detectCloudPlatform() {
    const hostname = window.location.hostname;
    
    if (hostname.includes('amazonaws.com') || hostname.includes('cloudfront.net')) {
        document.querySelector('.status-dot.aws').style.background = '#00b894';
        document.querySelector('.status-dot.azure').style.background = '#ddd';
    } else if (hostname.includes('azurewebsites.net') || hostname.includes('blob.core.windows.net')) {
        document.querySelector('.status-dot.azure').style.background = '#00b894';
        document.querySelector('.status-dot.aws').style.background = '#ddd';
    }
}

// Initialize
detectCloudPlatform();

// Demo weather data for testing without API key
if (!API_KEY || API_KEY === 'YOUR_OPENWEATHER_API_KEY') {
    cityInput.value = 'London';
    setTimeout(() => {
        const demoData = {
            name: 'London',
            sys: { country: 'GB' },
            main: {
                temp: 15,
                feels_like: 13,
                humidity: 72
            },
            weather: [{ description: 'partly cloudy' }],
            wind: { speed: 3.2 }
        };
        displayWeather(demoData);
    }, 1000);
}