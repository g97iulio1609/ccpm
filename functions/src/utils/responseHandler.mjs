export class ResponseHandler {
  static setCorsHeaders(response) {
    response.set('Access-Control-Allow-Origin', '*');
    response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    response.set('Access-Control-Max-Age', '3600');
  }

  static handleOptions(response) {
    this.setCorsHeaders(response);
    response.status(204).send('');
  }

  static success(response, data = {}) {
    this.setCorsHeaders(response);
    response.json({ success: true, ...data });
  }

  static error(response, error, status = 500) {
    this.setCorsHeaders(response);
    response.status(status).json({
      success: false,
      error: error.message || 'Internal server error'
    });
  }

  static unauthorized(response) {
    this.error(response, new Error('Unauthorized'), 401);
  }

  static forbidden(response) {
    this.error(response, new Error('Forbidden'), 403);
  }

  static notFound(response) {
    this.error(response, new Error('Not found'), 404);
  }
} 