export interface AeroAPIErrorOptions {
  code: string;
  status?: number;
  body?: string;
}

/** Error raised by the AeroAPI web client. */
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
