export interface AeroAPIErrorOptions {
  code: string;
  status?: number;
  body?: string;
}

/** Error raised by the AeroAPI web client. Codes match the Swift `AeroAPIError` cases. */
export class AeroAPIError extends Error {
  readonly code: string;
  readonly status?: number;
  readonly body?: string;

  constructor(message: string, options: AeroAPIErrorOptions) {
    super(message);
    this.name = "AeroAPIError";
    this.code = options.code;
    this.status = options.status;
    this.body = options.body;
  }
}

export const AeroErrors = {
  apiKeyNotSet(): AeroAPIError {
    return new AeroAPIError("No API Key set for the AeroAPI module.", { code: "apiKeyNotSet" });
  },
  invalidURLFromComponents(): AeroAPIError {
    return new AeroAPIError("Could not generate URL from components of AeroAPIRequest.", {
      code: "invalidURLFromComponents",
    });
  },
  http(status?: number, body?: string): AeroAPIError {
    return new AeroAPIError(`HTTP Response Error Code: ${status ?? 9999}`, {
      code: "HTTPResponseError",
      status,
      body,
    });
  },
  noData(status?: number): AeroAPIError {
    return new AeroAPIError("The HTTP Response was 200 but we did not return any data.", {
      code: "noDataReturnedForValidStatusCode",
      status,
    });
  },
  invalidMapHeight(height: number): AeroAPIError {
    return new AeroAPIError(
      `The height (${height}) given to the request for map data is invalid. It must be between 1 and 1500!`,
      { code: "invalidMapHeight" },
    );
  },
  invalidMapWidth(width: number): AeroAPIError {
    return new AeroAPIError(
      `The width (${width}) given to the request for map data is invalid. It must be between 1 and 1500!`,
      { code: "invalidMapWidth" },
    );
  },
  invalidDateAirportFlightsRequest(): AeroAPIError {
    return new AeroAPIError(
      "Start and End dates for an AirportFlightsRequest must be no further than a week in the past and two days in the future.",
      { code: "invalidDateAirportFlightsRequest" },
    );
  },
  startDateBeforeEndDate(): AeroAPIError {
    return new AeroAPIError("Start Date cannot be before the End Date.", { code: "startDateBeforeEndDate" });
  },
  faIdDateInvalid(id: string): AeroAPIError {
    return new AeroAPIError(`The FAID date string is invalid: ${id}`, { code: "faIdDateInvalid" });
  },
  failedDecodingScheduledFlightResponse(): AeroAPIError {
    return new AeroAPIError("Failed to decode the ScheduledFlightResponse", {
      code: "failedDecodingScheduledFlightResponse",
    });
  },
  failedDecodingMapData(): AeroAPIError {
    return new AeroAPIError("Failed to decode 'map' from JSON data response", { code: "failedDecodingMapData" });
  },
  flightTrackEmpty(): AeroAPIError {
    return new AeroAPIError("Flight Track response is empty", { code: "flightTrackEmpty" });
  },
  failedDecodingFlightTrackResponse(): AeroAPIError {
    return new AeroAPIError("Failed to decode the FlightTrackResponse", {
      code: "failedDecodingFlightTrackResponse",
    });
  },
  invalidJSON(status?: number, body?: string): AeroAPIError {
    return new AeroAPIError("Failed to decode the JSON response.", { code: "unexpected", status, body });
  },
  network(message: string): AeroAPIError {
    return new AeroAPIError(message, { code: "unexpected" });
  },
};
