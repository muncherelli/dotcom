# Technical Documentation

Complete technical documentation for the muncherelli.com project architecture, stack, and configuration.

## Technology Stack

### Core Framework

- **Next.js** - React framework with App Router
- **React** - UI library
- **React DOM** - React rendering for web
- **TypeScript** - Type-safe JavaScript

### Cloudflare Integration

- **OpenNext.js Cloudflare** (`@opennextjs/cloudflare`) - Adapter for deploying Next.js applications to Cloudflare Workers
- **Cloudflare Workers** - Serverless runtime environment
- **Wrangler** - CLI tool for Cloudflare Workers development and deployment

### Styling

- **Tailwind CSS v4.x** - Utility-first CSS framework
- **PostCSS** - CSS processing with Tailwind

### Development Tools

- **ESLint** - Code linting with Next.js config
- **Turbopack** - Fast bundler for development (enabled via `--turbopack` flag)

## Architecture Overview

This project is a Next.js application deployed to Cloudflare Workers using OpenNext.js Cloudflare adapter. The application runs entirely on Cloudflare's edge network, providing global distribution and low latency.

### Deployment Flow

1. **Build**: Next.js application is built using `next build`
2. **OpenNext Processing**: `@opennextjs/cloudflare` processes the Next.js build output
3. **Worker Generation**: Creates `.open-next/worker.js` that runs on Cloudflare Workers
4. **Asset Bundling**: Static assets are placed in `.open-next/assets` directory
5. **Deployment**: Worker and assets are deployed via Wrangler

## Cloudflare Bindings

The application uses several Cloudflare bindings configured in `wrangler.jsonc`:

### Database (D1)

- **Binding**: `DB`
- **Database ID**: `b18c7e48-39cf-4587-9df8-df36a3d45210`
- **Database Name**: `DOTCOM`
- **Type**: D1 (SQLite-based distributed database)
- **Usage**: Primary relational database for application data

### Key-Value Storage (KV)

- **Binding**: `KV`
- **Namespace ID**: `036160e2674f4f068a0f4f4a25c47f90`
- **Type**: Cloudflare KV (eventually consistent key-value store)
- **Usage**: Caching, session storage, or temporary data

### Object Storage (R2)

- **Binding**: `OBJECT`
- **Bucket Name**: `dotcom`
- **Type**: Cloudflare R2 (S3-compatible object storage)
- **Usage**: Media and article file storage

### Assets

- **Binding**: `ASSETS`
- **Directory**: `.open-next/assets`
- **Type**: Static asset serving
- **Usage**: Serves static files (CSS, JS, images) from the OpenNext build output

### Images

- **Binding**: `IMAGES`
- **Type**: Cloudflare Image Resizing
- **Usage**: Image optimization and resizing on-the-fly
- **Reference**: [OpenNext Image Optimization](https://opennext.js.org/cloudflare/howtos/image)

### Service Binding

- **Binding**: `WORKER_SELF_REFERENCE`
- **Service**: `dotcom`
- **Type**: Self-reference service binding
- **Usage**: Enables caching strategies by allowing the worker to call itself
- **Reference**: [OpenNext Caching](https://opennext.js.org/cloudflare/caching)

## Configuration Files

### `wrangler.jsonc`

Cloudflare Workers configuration file that defines:

- Worker name: `dotcom`
- Custom domain: `muncherelli.com`
- Compatibility date: `2025-12-01`
- Compatibility flags:
  - `nodejs_compat` - Enables Node.js compatibility APIs
  - `global_fetch_strictly_public` - Strict public fetch API
- Observability: Enabled for monitoring and debugging
- Route configuration: Custom domain routing (no `workers.dev` subdomain)

### `open-next.config.ts`

OpenNext.js Cloudflare adapter configuration:

- Currently uses default configuration
- R2 incremental cache is commented out but available for future use
- To enable R2 cache:

  ```typescript
  import r2IncrementalCache from "@opennextjs/cloudflare/overrides/incremental-cache/r2-incremental-cache";

  export default defineCloudflareConfig({
    incrementalCache: r2IncrementalCache,
  });
  ```

### `next.config.ts`

Next.js configuration:

- Minimal configuration (default settings)
- Includes OpenNext Cloudflare dev initialization for local development
- Enables `getCloudflareContext()` access in development mode
- Allows local access to Cloudflare bindings during development

### `package.json`

Project dependencies and scripts:

- **Development**: `pnpm run dev` - Runs Next.js dev server with Turbopack on port 1337
- **Build**: `pnpm run build` - Standard Next.js build
- **Deploy**: `pnpm run deploy` - Builds and deploys to Cloudflare
- **Upload**: `pnpm run upload` - Builds and uploads worker without deploying
- **Preview**: `pnpm run preview` - Builds and previews locally
- **Type Generation**: `pnpm run cf-typegen` - Generates TypeScript types for Cloudflare bindings. This needs to be ran any time the wrangler.jsonc file is changed.

## Bear.app SQLite Database Integration

### Overview

The project plans to integrate with Bear.app's SQLite database for content synchronization. Bear.app is a note-taking application for macOS/iOS that stores data in a local SQLite database.

### Current Status

Integration is planned but not yet implemented. The D1 database (`DB` binding) is configured and ready to receive synced data from Bear.app.

### Future Implementation: `sync.py`

A Python script (`sync.py`) is planned to handle the synchronization between Bear.app's SQLite database and Cloudflare D1. The script will:

1. **Read Bear.app Database**: Access the Bear.app SQLite database (typically located at `~/Library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data/database.sqlite`)

2. **Data Transformation**: Convert Bear.app note structure to the application's data model

3. **Sync to D1**: Use Cloudflare D1 API or Wrangler to sync data to the `DB` binding

4. **Incremental Updates**: Track changes and only sync modified notes

5. **Metadata Preservation**: Maintain Bear.app metadata (tags, creation dates, modification dates, etc.)

### Implementation Considerations

- **Authentication**: Secure access to Cloudflare D1 (API tokens or Wrangler authentication)
- **Schema Design**: Design D1 schema that maps Bear.app note structure
- **Conflict Resolution**: Handle conflicts when notes are modified in both systems
- **Scheduling**: Run sync script periodically (cron job, GitHub Actions, or local scheduler)
- **Error Handling**: Robust error handling for network issues, database locks, etc.

### Bear.app Database Schema (Reference)

Bear.app uses a SQLite database with tables such as:

- `ZSFNOTE` - Notes table
- `ZSFNOTETAG` - Note-tag relationships
- `ZSFBEAR` - Bear-specific metadata
- Additional tables for tags, attachments, etc.

The sync script will need to query these tables and transform the data appropriately.

## Application Structure

### Source Code (`src/`)

- `src/app/` - Next.js App Router directory
  - `layout.tsx` - Root layout with fonts (Geist Sans, Geist Mono) and global styles
  - `page.tsx` - Home page component
  - `globals.css` - Global CSS styles

### Build Output (`.open-next/`)

Generated during build process:

- `worker.js` - Main Cloudflare Worker entry point
- `assets/` - Static assets directory served via `ASSETS` binding

### Public Assets (`public/`)

- `favicon.svg` - Site favicon
- `_headers` - Cloudflare Pages headers configuration

## Development Workflow

### Local Development

```bash
pnpm run dev
```

- Runs Next.js development server with Turbopack
- Port: 1337
- Hot module replacement enabled
- Cloudflare bindings accessible via `getCloudflareContext()` in dev mode

### Preview Build

```bash
pnpm run preview
```

- Builds the application
- Previews the Cloudflare Worker locally
- Useful for testing production build before deployment

### Deployment

```bash
pnpm run deploy
```

- Builds the Next.js application
- Processes with OpenNext Cloudflare adapter
- Deploys to Cloudflare Workers
- Updates the `muncherelli.com` custom domain

## Type Safety

### Cloudflare Environment Types

TypeScript types for Cloudflare bindings are generated via:

```bash
pnpm run cf-typegen
```

This generates `cloudflare-env.d.ts` with type definitions for:

- D1 Database (`DB`)
- KV Namespaces (`KV`)
- R2 Buckets (`OBJECT`)
- Image Optimization (`IMAGES`)
- Assets (`ASSETS`)
- Service Bindings (`WORKER_SELF_REFERENCE`)

### Usage in Code

Access bindings in Next.js server components/API routes:

```typescript
import { getCloudflareContext } from "@opennextjs/cloudflare";

export async function GET() {
  const ctx = getCloudflareContext();
  const db = ctx.env.DB; // D1 Database
  const kv = ctx.env.KV; // KV Namespace
  const r2 = ctx.env.OBJECT; // R2 Bucket

  // Use bindings...
}
```

## Performance & Optimization

### Image Optimization

Cloudflare Images binding (`IMAGES`) provides:

- On-the-fly image resizing
- Format conversion (WebP, AVIF)
- Quality optimization
- CDN caching

### Caching Strategy

- **Static Assets**: Served via `ASSETS` binding with Cloudflare CDN
- **Incremental Cache**: Optional R2-based cache (currently disabled)
- **Service Binding**: Self-reference enables advanced caching patterns

### Edge Computing

All requests are processed at Cloudflare's edge locations worldwide, providing:

- Low latency
- Global distribution
- Automatic scaling
- DDoS protection

## Observability

Cloudflare Observability is enabled in `wrangler.jsonc`, providing:

- Request logging
- Error tracking
- Performance metrics
- Worker analytics

Access via Cloudflare Dashboard → Workers & Pages → dotcom → Observability

## Security Considerations

- **Custom Domain**: Uses `muncherelli.com` with SSL/TLS via Cloudflare
- **Environment Variables**: Sensitive data should use Cloudflare Secrets (not `vars` in `wrangler.jsonc`)
- **Database Access**: D1 database access is restricted to the Worker
- **Asset Serving**: Static assets served securely via Cloudflare CDN

## Future Enhancements

1. **Bear.app Sync**: Implement `sync.py` for Bear.app database synchronization
2. **R2 Caching**: Enable R2 incremental cache for improved performance
3. **Smart Placement**: Consider enabling Smart Placement for optimized worker execution
4. **Additional Bindings**: Add more Cloudflare services as needed (AI, Vectorize, etc.)

## References

- [OpenNext.js Cloudflare Documentation](https://opennext.js.org/cloudflare)
- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)
- [Wrangler Configuration](https://developers.cloudflare.com/workers/wrangler/configuration/)
- [Next.js 15 Documentation](https://nextjs.org/docs)
- [Cloudflare D1 Documentation](https://developers.cloudflare.com/d1/)
- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/)
- [Cloudflare KV Documentation](https://developers.cloudflare.com/kv/)
