# Weather API Backend

This backend server proxies requests to OpenWeatherMap API to keep the API key secure.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables in `.env`:
```
OPENWEATHER_API_KEY=your_api_key_here
PORT=3001
```

3. Start the server:
```bash
npm start
```

The API will be available at `http://localhost:3001/api/weather?city=CityName`

## Security

- API key is stored server-side in environment variables
- Frontend only communicates with your backend, never directly with OpenWeatherMap
- CORS enabled for frontend access