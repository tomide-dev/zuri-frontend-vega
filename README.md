# Zuri Market — Frontend

## Architecture Diagram
![Architecture Diagram](https://github.com/tomide-dev/zuri-frontend-vega/blob/main/Architecture%20Diagram.png)

## 1. Project Overview

This is the React frontend for Zuri Market. It displays products fetched from the backend API, lets the user filter products by category, and includes a cart with quantity management. The user sees a storefront — a hero banner, a filterable product grid, and a slide-out cart — and every product/store request goes to a separate backend API over HTTP.

## 2. Tech Stack

- **React** 18.3
- **Vite** 7.3 (dev server + production bundler)
- **@vitejs/plugin-react** — React Fast Refresh support for Vite
- Plain CSS (custom properties), no CSS framework
- **Node.js** 20 required to install dependencies and run the dev server/build (the Docker image is built on `node:20-alpine`)

## 3. Project Structure

```
zuriapp-frontend/
├── .github/
│   └── workflows/
│       └── frontend-ci.yml        # CI/CD: test, audit, build, scan, push, deploy to k3s
├── k8s/
│   └── frontend-deployment.yaml         # Kubernetes Deployment + NodePort Service
    └── frontend-service.yaml
├── src/
│   ├── components/
│   │   ├── Navbar.jsx          # Store name, nav links, cart button with item-count badge
│   │   ├── Hero.jsx             # Landing banner: headline, intro copy, CTA buttons
│   │   ├── FilterBar.jsx        # Category filter pills (All / Gear / Apparel / Home / Tech)
│   │   ├── ProductGrid.jsx      # Grid layout + loading skeletons, error state, empty state
│   │   ├── ProductCard.jsx      # Single product card with image, price, "Add to cart"
│   │   └── CartSidebar.jsx      # Slide-out cart: line items, quantity steppers, subtotal
│   ├── hooks/
│   │   └── useCart.js            # Cart state: add/remove/update/clear, derived count & total
│   ├── App.jsx                    # Top-level state, data fetching, wires everything together
│   ├── main.jsx                    # React root render
│   └── index.css                    # Global styles & CSS custom properties (theme variables)
├── index.html                          # HTML entry point, loads /src/main.jsx as a module
├── vite.config.js                       # Dev server port + /api proxy to the backend
├── Dockerfile                            # Two-stage build: Node build stage → Nginx runtime
├── .dockerignore
├── .env.example                            # Template listing required environment variables
├── .gitignore
├── package.json
└── package-lock.json
```

- **`vite.config.js`** — Fixes the dev server to port `3000` and proxies any `/api/*` request to the backend URL set in `VITE_API_URL`.
- **`index.html`** — The single HTML page Vite serves; it just mounts the React app via `/src/main.jsx`.
- **`Dockerfile`** — Builds the production image (see [Docker](#7-docker) below).
- **`k8s/frontend-deployment.yaml`** — Describes how the app runs in Kubernetes once deployed.
- **`.github/workflows/frontend-ci.yml`** — The pipeline that builds, scans, pushes, and deploys the app on every push to `main`.

### `src/` in detail

- **`Navbar.jsx`** — Renders the store name and a cart button with an item-count badge. Receives `storeName`, `cartCount`, `onCartOpen`.
- **`Hero.jsx`** — Renders the landing banner/headline below the navbar. Receives `storeName`.
- **`FilterBar.jsx`** — Renders the row of category pills (`all`, `gear`, `apparel`, `home`, `tech`). Receives `activeCategory`, `onCategoryChange`.
- **`ProductGrid.jsx`** — Renders the grid of products, or a skeleton/error/empty state depending on fetch status. Receives `products`, `loading`, `error`, `onAddToCart`.
- **`ProductCard.jsx`** — Renders a single product (image, category, name, description, price, "Add to cart" button). Receives `product`, `onAddToCart`.
- **`CartSidebar.jsx`** — Renders the slide-out cart with line items, quantity steppers, subtotal, and checkout/clear buttons. Receives `cartItems`, `cartTotal`, `onRemove`, `onUpdateQuantity`, `onClear`, `onClose`.
- **`useCart.js`** — Custom hook holding cart state and exposing `cartItems`, `addToCart`, `removeFromCart`, `updateQuantity`, `clearCart`, `cartCount`, `cartTotal`.
- **`App.jsx`** — Fetches `/api/store` and `/api/products` on load and whenever the active category changes, manages cart-sidebar open/close state, and passes data/handlers down to every component above.

## 4. Environment Variables

| Variable | Description |
|---|---|
| `VITE_API_URL` | Base URL of the backend API (e.g. `http://localhost:5000`) |
| `VITE_STORE_NAME` | Fallback store name shown if the `/api/store` request fails |

Vite only exposes environment variables to browser code if they're prefixed with `VITE_`. Any variable without that prefix (e.g. just `API_URL`) will be `undefined` in the app — it exists in the build environment but is never injected into the client bundle. This is a Vite security default, not a bug, so don't drop the prefix when adding new variables.

Copy `.env.example` to `.env` and fill in your values before running the app:

```bash
cp .env.example .env
```

## 5. Running Locally

```bash
# 1. Clone the repo
git clone https://github.com/tomide-dev/zuri-frontend-vega.git
cd zuriapp-frontend

# 2. Install dependencies
npm install

# 3. Set up environment variables
cp .env.example .env
# then edit .env and set VITE_API_URL / VITE_STORE_NAME

# 4. Start the dev server
npm run dev
```

The dev server starts on **`http://localhost:3000`** (port is fixed in `vite.config.js`). Any request to `/api/*` is proxied from there to whatever `VITE_API_URL` resolves to, so the browser always talks to `localhost:3000` and never needs CORS configured for local dev.

The backend API must also be running (at the URL set in `VITE_API_URL`, default `http://localhost:5000`) for the storefront to load — without it, the product grid will show its error state and the store name will fall back to `VITE_STORE_NAME`.

## 6. Building for Production

```bash
npm run build
```

This runs `vite build` and outputs a static, optimized bundle to the `dist/` folder. `dist/` is what gets copied into the Nginx layer of the Docker image — it's the only build artifact the container ever serves. It's excluded from Git (see `.gitignore`) since it's generated on every build, not checked-in source.

You can sanity-check the production build locally before deploying:

```bash
npm run preview
```

## 7. Docker

```bash
docker build -t tomidedev/zuriapp-frontend .
docker run -p 3000:80 tomidedev/zuriapp-frontend
```

Docker Hub image: **`tomidedev/zuriapp-frontend`**

> In the CI/CD pipeline, `VITE_API_URL` is set to the backend's NodePort address on the EC2 host (`http://<EC2_PUBLIC_IP>:30080`) at build time, since `VITE_API_URL` gets baked into the static bundle — it can't be changed after the image is built.

## 8. Component Reference

| Component | Renders | Receives (props) |
|---|---|---|
| `Navbar` | Store name + nav links + cart button with item badge | `storeName`, `cartCount`, `onCartOpen` |
| `Hero` | Landing banner with headline and CTA buttons | `storeName` |
| `FilterBar` | Category filter pills | `activeCategory`, `onCategoryChange` |
| `ProductGrid` | Product card grid, loading skeletons, error message, or empty state | `products`, `loading`, `error`, `onAddToCart` |
| `ProductCard` | Single product: image, category, name, description, price, add-to-cart button | `product`, `onAddToCart` |
| `CartSidebar` | Slide-out panel: cart line items, quantity steppers, subtotal, checkout/clear buttons | `cartItems`, `cartTotal`, `onRemove`, `onUpdateQuantity`, `onClear`, `onClose` |
