---
name: get_weather
description: Retrieve the current weather for a requested city or location
version: "1.0"
inputs:
  - name: city
    type: string
    description: City or location to look up, such as "Phoenix" or "Phoenix, AZ"
    required: true
outputs:
  - name: forecast
    type: string
    description: Concise current weather summary for the requested location
---

## Purpose
Provide a concise, current weather update for a user-specified location.

## When to Use
- The user asks for the current weather, forecast, temperature, or conditions
- The user names a city, town, or region and wants to know what the weather is like now
- The user asks a follow-up weather question about a location already established in context

## When NOT to Use
- The user asks about historical climate trends, averages, or seasonality
- The user asks for unrelated geographic, demographic, or travel information
- The user asks for emergency guidance, radar interpretation, or severe weather safety advice
- The location is too ambiguous to resolve confidently

## Instructions
1. Identify the location from the user's request or recent conversation context.
2. Normalize the location into a searchable form, adding state or country when it is obvious from context.
3. Use the `web_search` tool to look up the current weather for that location.
4. Prefer a search phrasing like `current weather <location>` or `weather today <location>`.
5. Extract the most relevant current conditions, including temperature and a short condition summary.
6. If reliable near-term forecast details are available, include one brief high/low or short forecast sentence.
7. Return the weather answer directly after gathering the result.
8. If the location is ambiguous and cannot be resolved confidently, ask for clarification instead of guessing.

## Response Style
- State the location clearly.
- Prefer a single short paragraph.
- Include temperature and conditions in Farenheit and Celsius.
- If available, include one short forecast detail for later today.
- Answer only with the weather result.
- Do not end with follow-up offers such as "If you want..." or "I can also...".
- Do not suggest next steps unless the user explicitly asks for more detail.
- Do not mention shell commands, files, or `SKILL.md`.
- Do not say that you are "using the skill" or "looking it up" unless the user explicitly asks.
- Do not invent values that were not found.

## Examples

### Input
city: "Phoenix"

### Output
"It's currently 78°F and sunny in Phoenix, AZ."

### Input
city: "London"

### Output
"It's currently 61°F and cloudy in London, with light rain possible later today."
