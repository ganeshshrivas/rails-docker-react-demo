# Nginx

Production routing is configured in `frontend/nginx/default.conf`:

- `/` serves the React SPA
- `/api/*` is proxied to the Rails backend (prefix stripped)

The frontend Docker image bundles this Nginx configuration.
