export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Define routes to your backend services
    const routes = {
      '/api/auth':    env.AUTH_SERVICE_URL,
      '/api/catalog': env.CATALOG_SERVICE_URL,
      '/api/order':   env.ORDER_SERVICE_URL,
      '/api/user':    env.USER_SERVICE_URL,
      '/health':      env.CATALOG_SERVICE_URL, // Example: route /health to catalog
    };

    // Find the backend service that matches the start of the request path
    const match = Object.keys(routes).find(path => url.pathname.startsWith(path));

    if (!match) {
      return new Response('Not found', { status: 404 });
    }

    // Set the hostname to the correct backend service
    const upstreamHostname = new URL(routes[match]).hostname;
    url.hostname = upstreamHostname;

    const newRequest = new Request(url.toString(), request);

    // Add a correlation ID for easier debugging
    newRequest.headers.set('x-correlation-id', crypto.randomUUID());

    return fetch(newRequest);
  }
};