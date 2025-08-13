// workers/edge-proxy/src/index.js
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Set the hostname to the App Runner service URL
    url.hostname = env.CATALOG_SERVICE_URL;

    // Create a new request object, passing the original request to preserve its properties
    const newRequest = new Request(url, request);

    return fetch(newRequest);
  }
}