const API_KEY = process.env.OPENWEATHER_API_KEY;

exports.handler = async (event) => {
  const headers = {
    "Content-Type": "application/json"
  };

  if (event.requestContext.http.method === "POST") {
    return { statusCode: 200, headers };
  }

  if (
    event.requestContext.http.method !== "GET" ||
    !event.rawPath.includes("/api/weather")
  ) {
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: "Not found" }),
    };
  }

  const city = event.queryStringParameters?.city;

  if (!city) {
    return {
      statusCode: 400,
      headers,
      body: JSON.stringify({ error: "City parameter is required" }),
    };
  }

  if (!API_KEY) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "API key not configured" }),
    };
  }

  try {
    const url = `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(
      city
    )}&appid=${API_KEY}&units=metric`;

    const response = await fetch(url);
    const data = await response.json();

    if (!response.ok) {
      return {
        statusCode: response.status,
        headers,
        body: JSON.stringify(data),
      };
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify(data),
    };
  } catch (error) {
    console.error("Weather API error:", error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
};
