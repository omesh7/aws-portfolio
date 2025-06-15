exports.handler = async (event) => {
    console.log("Received event:", JSON.stringify(event));

    const intent = event.request?.intent?.name || "Unknown";

    let speechText = "Hello! This is your custom Alexa skill.";

    if (intent === "GetProjectCountIntent") {
        const projectCount = 2; // Later fetch dynamically if needed
        speechText = `You have completed ${projectCount} AWS projects so far. Keep going!`;
    }

    return {
        version: "1.0",
        response: {
            outputSpeech: {
                type: "PlainText",
                text: speechText,
            },
            shouldEndSession: true,
        },
    };
};
